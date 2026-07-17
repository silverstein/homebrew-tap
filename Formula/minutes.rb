class Minutes < Formula
  desc "Conversation memory for AI assistants — record, transcribe, search"
  homepage "https://useminutes.app"
  url "https://github.com/silverstein/minutes.git", tag: "v0.21.0"
  license "MIT"

  depends_on "cmake" => :build
  depends_on "rust" => :build

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

    system "cargo", "install", "--path", "crates/cli", "--root", prefix
  end

  def post_install
    ohai "Run 'minutes setup --model small' to download the whisper model (~466MB)"
    ohai "Run 'minutes health' to check your system readiness"
  end

  test do
    assert_match "minutes", shell_output("#{bin}/minutes --version")
    # Test that status works without a recording
    output = shell_output("#{bin}/minutes status")
    assert_match "recording", output
  end
end
