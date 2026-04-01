class Minutes < Formula
  desc "Conversation memory for AI assistants — record, transcribe, search"
  homepage "https://useminutes.app"
  url "https://github.com/silverstein/minutes.git", tag: "v0.9.3"
  license "MIT"

  depends_on "rust" => :build
  depends_on "cmake" => :build

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
