cask "minutes" do
  version "0.27.0"
  sha256 "392594b7311bc3143861329a38df5465d04e2930cdfa34b50da7ad44ea5ff8ab"

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
