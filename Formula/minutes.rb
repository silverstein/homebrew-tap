class Minutes < Formula
  desc "Conversation memory for AI assistants — record, transcribe, search"
  homepage "https://github.com/silverstein/minutes"
  url "https://github.com/silverstein/minutes.git", tag: "v0.1.0"
  license "MIT"

  depends_on "rust" => :build
  depends_on "cmake" => :build

  def install
    system "cargo", "install", "--path", "crates/cli", "--root", prefix
  end

  def post_install
    ohai "Run 'minutes setup --model small' to download the whisper model (~466MB)"
    ohai "Run 'minutes devices' to check your audio input devices"
  end

  test do
    assert_match "minutes", shell_output("#{bin}/minutes --version")
    # Test that status works without a recording
    output = shell_output("#{bin}/minutes status")
    assert_match "recording", output
  end
end
