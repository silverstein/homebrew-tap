class Minutes < Formula
  desc "Conversation memory for AI assistants — record, transcribe, search"
  homepage "https://useminutes.app"
  url "https://github.com/silverstein/minutes.git", tag: "v0.26.3"
  license "MIT"

  depends_on "cmake" => :build
  depends_on "rust" => :build

  # silverstein/minutes#1000. Without this, `brew install` produces a build that
  # cannot run sherpa, while `minutes setup --list` recommends sherpa for
  # multilingual work. A bilingual user followed that advice, downloaded 639 MB
  # of Parakeet v3, had `engine = "sherpa"` written into their config, and got
  # silent whisper fallback from then on.
  #
  # The CLI side of the feature is cheap: `engine-sherpa` adds only `libloading`,
  # because the recognizer lives in a separate dylib that is dlopened at runtime.
  # That dylib cannot be built here (crates/sherpa-plugin downloads a prebuilt
  # sherpa-onnx bundle during its build, which the formula sandbox does not
  # allow), so the Developer ID signed one from the matching release is staged as
  # a resource instead. It must land beside the binary: that is the first path
  # the loader checks, and how the release archives and the macOS app ship it.
  on_macos do
    on_arm do
      resource "sherpa-plugin" do
        url "https://github.com/silverstein/minutes/releases/download/v0.26.3/minutes-macos-arm64-sherpa.tar.gz"
        sha256 "e357ae1a654ccc1774d27b9c9184ba257dc145b195331e8fabc6c5478fa4d6f1"
      end
    end
  end

  def install
    # whisper.cpp (via cmake) needs C++ includes and deployment target on macOS 15+/Xcode 26+
    sdk_path = Utils.safe_popen_read("xcrun", "--show-sdk-path").chomp
    cpp_include = "#{sdk_path}/usr/include/c++/v1"
    if Dir.exist?(cpp_include)
      ENV.append "CXXFLAGS", "-I#{cpp_include}"
      ENV["CPLUS_INCLUDE_PATH"] = cpp_include
    end
    ENV["MACOSX_DEPLOYMENT_TARGET"] = "11.0"
    ENV["CMAKE_OSX_DEPLOYMENT_TARGET"] = "11.0"

    # silverstein/minutes#89: whisper.cpp's bundled CMakeLists has
    # GGML_CCACHE=ON by default. If a user has ccache installed (e.g. via
    # Homebrew at /opt/homebrew/bin/ccache), find_program() locates it at
    # cmake-configure time and sets it as the global compile-rule launcher.
    # At make-time the resulting `ccache <compiler> ...` invocation runs
    # through /bin/sh with Homebrew's sanitized superenv PATH, which doesn't
    # expose ccache unless declared as a build dep, and the compile fails
    # with "ccache: command not found" / Error 127.
    #
    # whisper-rs-sys forwards any GGML_*, WHISPER_*, or CMAKE_* env var to
    # cmake as -D<KEY>=<VALUE> (see whisper-rs-sys/build.rs), so disabling
    # GGML_CCACHE here propagates cleanly through to whisper.cpp's CMake and
    # skips the entire ccache discovery block at the source. No new build
    # dep required, deterministic regardless of the user's ccache state.
    ENV["GGML_CCACHE"] = "OFF"

    # Apple Silicon is the only platform with a published, signed plugin, so it
    # is the only one that gets the loader compiled in. Elsewhere the feature
    # would just be a loader with nothing to load.
    sherpa = OS.mac? && Hardware::CPU.arm?
    args = ["cargo", "install", "--path", "crates/cli", "--root", prefix]
    args += ["--features", "engine-sherpa"] if sherpa
    system(*args)

    if sherpa
      resource("sherpa-plugin").stage do
        bin.install "minutes-macos-arm64-sherpa/libminutes_sherpa.dylib"
      end
    end
  end

  def post_install
    ohai "Run 'minutes setup --model small' to download the whisper model (~466MB)"
    ohai "Run 'minutes health' to check your system readiness"
    if OS.mac? && Hardware::CPU.arm?
      ohai "Parakeet v3 (multilingual) is available: 'minutes setup --sherpa' (~670MB)"
    end
  end

  test do
    assert_match "minutes", shell_output("#{bin}/minutes --version")
    # Test that status works without a recording
    output = shell_output("#{bin}/minutes status")
    assert_match "recording", output
  end
end
