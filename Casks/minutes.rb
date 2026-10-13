cask "minutes" do
  version "0.29.0"
  sha256 "2cce1729a988ce92b6a3822324b64280e3c5407eca08bf824320dc1c8dd622c7"

  url "https://github.com/silverstein/minutes/releases/download/v#{version}/Minutes_#{version}_aarch64.dmg"
  name "Minutes"
  desc "Meeting recorder and transcriber that runs on-device"
  homepage "https://useminutes.app/"

  depends_on macos: :sonoma
  depends_on arch: :arm64

  app "Minutes.app"

  zap trash: [
    "~/.config/minutes",
    "~/.minutes",
  ]

  caveats <<~EOS
    Native call capture (the "Call detected" banner with system audio) needs macOS 15 or newer.

    To download a whisper model for transcription:
      minutes setup --model small

    For the CLI (record, stop, search from terminal):
      brew install silverstein/tap/minutes
  EOS
end
