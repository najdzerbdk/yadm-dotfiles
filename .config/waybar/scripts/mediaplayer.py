#!/usr/bin/env python3
import gi
gi.require_version("Playerctl", "2.0")
from gi.repository import Playerctl, GLib
from gi.repository.Playerctl import Player
import argparse
import logging
import sys
import signal
import gi
import json
import os
from typing import List

logger = logging.getLogger(__name__)

def signal_handler(sig, frame):
    logger.info("Received signal to stop, exiting")
    sys.stdout.write("\n")
    sys.stdout.flush()
    sys.exit(0)


class PlayerManager:
    def __init__(self):
        self.manager = Playerctl.PlayerManager()
        self.loop = GLib.MainLoop()
        self.manager.connect("name-appeared", self.on_player_appeared)
        self.manager.connect("player-vanished", self.on_player_vanished)

        signal.signal(signal.SIGINT, signal_handler)
        signal.signal(signal.SIGTERM, signal_handler)
        signal.signal(signal.SIGPIPE, signal.SIG_DFL)

        self.active_player = None
        self.init_players()

    def init_players(self):
        # Only initialize Spotify players
        for player in self.manager.props.player_names:
            if player.name == "spotify":
                self.init_player(player)

    def on_player_appeared(self, _, player):
        # Only handle Spotify players
        if player.name == "spotify":
            self.init_player(player)

    def on_player_vanished(self, _, player):
        logger.info(f"Player {player.props.player_name} has vanished")
        # Only care about Spotify players vanishing
        if player.props.player_name == "spotify":
            if self.active_player and self.active_player.props.player_name == player.props.player_name:
                self.active_player = None
                self.clear_output()

    def init_player(self, player):
        logger.info(f"Initialize new player: {player.name}")
        player = Playerctl.Player.new_from_name(player)
        player.connect("playback-status", self.on_playback_status_changed, None)
        player.connect("metadata", self.on_metadata_changed, None)
        self.manager.manage_player(player)
        self.active_player = player

    def run(self):
        logger.info("Starting main loop")
        self.loop.run()

    def write_output(self, text, player):
        logger.debug(f"Writing output: {text}")

        output = {"text": text,
                  "class": "custom-spotify",
                  "alt": "spotify"}

        sys.stdout.write(json.dumps(output) + "\n")
        sys.stdout.flush()

    def clear_output(self):
        sys.stdout.write("\n")
        sys.stdout.flush()

    def on_playback_status_changed(self, player, status, _=None):
        # Only process Spotify players
        if player.props.player_name != "spotify":
            return
            
        logger.debug(f"Playback status changed for player {player.props.player_name}: {status}")
        self.active_player = player
        self.update_display(player)

    def on_metadata_changed(self, player, metadata, _=None):
        # Only process Spotify players
        if player.props.player_name != "spotify":
            return
            
        logger.debug(f"Metadata changed for player {player.props.player_name}")
        self.active_player = player
        self.update_display(player)

    def update_display(self, player):
        # Only process Spotify players
        if player.props.player_name != "spotify":
            return
            
        metadata = player.props.metadata
        artist = player.get_artist() or ""
        title = player.get_title() or ""
        artist = artist.replace("&", "&amp;")
        title = title.replace("&", "&amp;")

        if "mpris:trackid" in metadata.keys() and ":ad:" in metadata["mpris:trackid"]:
            track_info = "Advertisement"
        else:
            track_info = f"{artist} - {title}".strip()

        if player.props.status == "Playing":
            track_info = "   " + track_info
        else:
            track_info = "   " + track_info

        self.write_output(track_info, player)


def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument("-v", "--verbose", action="count", default=0)
    parser.add_argument("--enable-logging", action="store_true")
    return parser.parse_args()


def main():
    arguments = parse_arguments()

    if arguments.enable_logging:
        logfile = os.path.join(os.path.dirname(
            os.path.realpath(__file__)), "media-player.log")
        logging.basicConfig(filename=logfile, level=logging.DEBUG,
                            format="%(asctime)s %(name)s %(levelname)s:%(lineno)d %(message)s")

    logger.setLevel(max((3 - arguments.verbose) * 10, 0))

    logger.info("Creating Spotify-only player manager")
    player = PlayerManager()
    player.run()


if __name__ == "__main__":
    main()