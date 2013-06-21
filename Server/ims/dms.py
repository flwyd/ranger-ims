##
# See the file COPYRIGHT for copyright information.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##

"""
Duty Management System integration.
"""

__all__ = [
    "DutyManagementSystem",
]

from time import time

from twisted.python import log
from twisted.python.failure import Failure
from twisted.internet.defer import succeed
from twisted.enterprise import adbapi

from ims.data import Ranger



class DatabaseError(Exception):
    """
    Database error.
    """



class DutyManagementSystem(object):
    """
    Duty Management System
    """
    rangers_cache_interval = 60 * 60 * 1 # 1 hour

    def __init__(self, host, database, username, password):
        if host is None:
            self.dbpool = None
        else:
            self.dbpool = adbapi.ConnectionPool(
                "mysql.connector",
                host=host, database=database,
                user=username, password=password,
            )


    def allRangers(self):
        #
        # No self.dbpool means no database was configured.
        # Return a dummy set for testing.
        #
        if self.dbpool is None:
            return succeed(
                Ranger(handle, None, None)
                for handle in allRangerHandles
            )

        #
        # If we've cached the list of Rangers and the cache is not
        # older than self.rangers_cache_interval, return the cached
        # value.
        #
        if hasattr(self, "_rangers") and hasattr(self, "_rangers_updated"):
            log.msg("...have cached Rangers")
            now = time()
            if now - self._rangers_updated <= self.rangers_cache_interval:
                log.msg("Returning Rangers from cache.")
                return self._rangers

        #
        # Ask the Ranger database for a list of Rangers.
        #
        log.msg("{0} Retrieving Rangers from Duty Management System...".format(self))

        d = self.dbpool.runQuery("""
            select callsign, first_name, mi, last_name, status
            from person
            where status not in (
                'prospective', 'alpha',
                'bonked', 'uberbonked',
                'deceased'
            )
        """)

        def onError(f):
            log.err(f)
            return Failure(DatabaseError(f.value))

        d.addErrback(onError)

        def onData(results):
            rangers = [
                Ranger(handle, fullName(first, middle, last), status)
                for handle, first, middle, last, status
                in results
            ]

            self._rangers = rangers
            self._rangers_updated = time()

            log.msg("Returning Rangers from db.")
            return self._rangers

        d.addCallback(onData)

        return d



def fullName(first, middle, last):
    if middle:
        return "{first} {middle}. {last}".format(
            first=first, middle=middle, last=last
        )
    else:
        return "{first} {last}".format(
            first=first, middle=middle, last=last
        )



allRangerHandles = (
    "2Wilde",
    "Abakus",
    "Abe",
    "ActionJack",
    "Africa",
    "Akasha",
    "Amazon",
    "Anime",
    "Answergirl",
    "Apparatus",
    "Archer",
    "Atlantis",
    "Atlas",
    "Atomic",
    "Atticus",
    "Avatar",
    "Awesome Sauce",
    "Axle",
    "Baby Huey",
    "Babylon",
    "Bacchus",
    "Backbone",
    "Bass Clef",
    "Batman",
    "Bayou",
    "Beast",
    "Beauty",
    "Bedbug",
    "Belmont",
    "Bender",
    "Beow",
    "Big Bear",
    "BioBoy",
    "Bjorn",
    "BlackSwan",
    "Blank",
    "Bluefish",
    "Bluetop",
    "Bobalicious",
    "Bobo",
    "Boiler",
    "Boisee",
    "Boots n Katz",
    "Bourbon",
    "Boxes",
    "BrightHeart",
    "Brooklyn",
    "Brother",
    "Buick",
    "Bumblebee",
    "Bungee Girl",
    "Butterman",
    "Buzcut",
    "Bystander",
    "CCSallie",
    "Cabana",
    "Cajun",
    "Camber",
    "Capitana",
    "Capn Ron",
    "Carbon",
    "Carousel",
    "Catnip",
    "Cattus",
    "Chameleon",
    "Chenango",
    "Cherub",
    "Chi Chi",
    "Chilidog",
    "Chino",
    "Chyral",
    "Cilantro",
    "Citizen",
    "Climber",
    "Cobalt",
    "Coconut",
    "Cousteau",
    "Cowboy",
    "Cracklepop",
    "Crawdad",
    "Creech",
    "Crizzly",
    "Crow",
    "Cucumber",
    "Cursor",
    "DL",
    "Daffydell",
    "Dandelion",
    "Debris",
    "Decoy",
    "Deepwater",
    "Delco",
    "Deuce",
    "Diver Dave",
    "Dixie",
    "Doc Rox",
    "Doodlebug",
    "Doom Raider",
    "Dormouse",
    "Double G",
    "Double R",
    "Doumbek",
    "Ducky",
    "Duct Tape Diva",
    "Duney Dan",
    "DustOff",
    "East Coast",
    "Easy E",
    "Ebbtide",
    "Edge",
    "El Cid",
    "El Weso",
    "Eldo",
    "Enigma",
    "Entheo",
    "Esoterica",
    "Estero",
    "Europa",
    "Eyepatch",
    "Fable",
    "Face Plant",
    "Fairlead",
    "Falcore",
    "Famous",
    "Farmer",
    "Fat Chance",
    "Fearless",
    "Feline",
    "Feral Liger",
    "Fez Monkey",
    "Filthy",
    "Firecracker",
    "Firefly",
    "Fishfood",
    "Fixit",
    "Flat Eric",
    "Flint",
    "Focus",
    "Foofurr",
    "FoxyRomaine",
    "Freedom",
    "Freefall",
    "Full Gear",
    "Fuzzy",
    "G-Ride",
    "Gambol",
    "Garnet",
    "Gecko",
    "Gemini",
    "Genius",
    "Geronimo",
    "Gibson",
    "Gizmo",
    "Godess",
    "Godfather",
    "Gonzo",
    "Goodwood",
    "Great White",
    "Grim",
    "Grofaz",
    "Grooves",
    "Grounded",
    "Guitar Hero",
    "Haggis",
    "Haiku",
    "Halston",
    "HappyFeet",
    "Harvest",
    "Hattrick",
    "Hawkeye",
    "Hawthorn",
    "Hazelnut",
    "Heart Touch",
    "Heartbeat",
    "Heaven",
    "Hellboy",
    "Hermione",
    "Hindsight",
    "Hitchhiker",
    "Hogpile",
    "Hole Card",
    "Hollister",
    "Homebrew",
    "Hookah Mike",
    "Hooper",
    "Hoopy Frood",
    "Horsforth",
    "Hot Slots",
    "Hot Yogi",
    "Howler",
    "Hughbie",
    "Hydro",
    "Ice Cream",
    "Igor",
    "Improvise",
    "Incognito",
    "India Pale",
    "Inkwell",
    "Iron Squirrel",
    "J School",
    "J.C.",
    "JTease",
    "Jake",
    "Jellyfish",
    "Jester",
    "Joker",
    "Judas",
    "Juniper",
    "Just In Case",
    "Jynx",
    "Kamshaft",
    "Kansas",
    "Katpaw",
    "Kaval",
    "Keeper",
    "Kendo",
    "Kermit",
    "Kettle-Belle",
    "Kilrog",
    "Kimistry",
    "Kingpin",
    "Kiote",
    "KitCarson",
    "Kitsune",
    "Komack",
    "Kotekan",
    "Krusher",
    "Kshemi",
    "Kuma",
    "Kyrka",
    "LK",
    "LadyFrog",
    "Laissez-Faire",
    "Lake Lover",
    "Landcruiser",
    "Larrylicious",
    "Latte",
    "Leeway",
    "Lefty",
    "Legba",
    "Legend",
    "Lens",
    "Librarian",
    "Limoncello",
    "Little John",
    "LiveWire",
    "Lodestone",
    "Loki",
    "Lola",
    "Lone Rider",
    "LongPig",
    "Lorenzo",
    "Loris",
    "Lothos",
    "Lucky Charm",
    "Lucky Day",
    "Lushus",
    "M-Diggity",
    "Madtown",
    "Magic",
    "Magnum",
    "Mailman",
    "Malware",
    "Mammoth",
    "Manifest",
    "Mankind",
    "Mardi Gras",
    "Martin Jay",
    "Massai",
    "Mauser",
    "Mavidea",
    "Maximum",
    "Maxitude",
    "Maybe",
    "Me2",
    "Mellow",
    "Mendy",
    "Mere de Terra",
    "Mickey",
    "Milky Wayne",
    "MisConduct",
    "Miss Piggy",
    "Mockingbird",
    "Mongoose",
    "Monkey Shoes",
    "Monochrome",
    "Moonshine",
    "Morning Star",
    "Mouserider",
    "Moxie",
    "Mr Po",
    "Mucho",
    "Mufasa",
    "Muppet",
    "Mushroom",
    "NaFun",
    "Nekkid",
    "Neuron",
    "Newman",
    "Night Owl",
    "Nobooty",
    "Nosler",
    "Notorious",
    "Nuke",
    "NumberNine",
    "Oblio",
    "Oblivious",
    "Obtuse",
    "Octane",
    "Oddboy",
    "Old Goat",
    "Oliphant",
    "One Trip",
    "Onyx",
    "Orion",
    "Osho",
    "Oswego",
    "Outlaw",
    "Owen",
    "Painless",
    "Pandora",
    "Pappa Georgio",
    "Paragon",
    "PartTime",
    "PawPrint",
    "Pax",
    "Peaches",
    "Peanut",
    "Phantom",
    "Philamonjaro",
    "Picante",
    "Pigmann",
    "Piney Fresh",
    "Pinstripes",
    "Pinto",
    "Piper",
    "PitBull",
    "Po-Boy",
    "PocketPunk",
    "Pokie",
    "Pollux",
    "Polymath",
    "PopTart",
    "Potato",
    "PottyMouth",
    "Prana",
    "Princess",
    "Prunetucky",
    "Pucker-Up",
    "Pudding",
    "Pumpkin",
    "Quandary",
    "Queen SOL",
    "Quincy",
    "Raconteur",
    "Rat Bastard",
    "Razberry",
    "Ready",
    "Recall",
    "Red Raven",
    "Red Vixen",
    "Redeye",
    "Reject",
    "RezzAble",
    "Rhino",
    "Ric",
    "Ricky San",
    "Riffraff",
    "RoadRash",
    "Rockhound",
    "Rocky",
    "Ronin",
    "Rooster",
    "Roslyn",
    "Sabre",
    "Safety Phil",
    "Safeword",
    "Salsero",
    "Samba",
    "Sandy Claws",
    "Santa Cruz",
    "Sasquatch",
    "Saturn",
    "Scalawag",
    "Scalpel",
    "SciFi",
    "ScoobyDoo",
    "Scooter",
    "Scoutmaster",
    "Scuttlebutt",
    "Segovia",
    "Sequoia",
    "Sharkbite",
    "Sharpstick",
    "Shawnee",
    "Shenanigans",
    "Shiho",
    "Shizaru",
    "Shrek",
    "Shutterbug",
    "Silent Wolf",
    "SilverHair",
    "Sinamox",
    "Sintine",
    "Sir Bill",
    "Skirblah",
    "Sledgehammer",
    "SlipOn",
    "Smithers",
    "Smitty",
    "Smores",
    "Snappy",
    "Snowboard",
    "Snuggles",
    "SpaceCadet",
    "Spadoinkle",
    "Spastic",
    "Spike Brown",
    "Splinter",
    "Sprinkles",
    "Starfish",
    "Stella",
    "Sticky",
    "Stitch",
    "Stonebeard",
    "Strider",
    "Strobe",
    "Strong Tom",
    "Subway",
    "Sunbeam",
    "Sundancer",
    "SuperCraig",
    "Sweet Tart",
    "Syncopate",
    "T Rex",
    "TSM",
    "Tabasco",
    "Tagalong",
    "Tahoe",
    "Tango Charlie",
    "Tanuki",
    "Tao Skye",
    "Tapestry",
    "Teardrop",
    "Teksage",
    "Tempest",
    "Tenderfoot",
    "The Hamptons",
    "Thirdson",
    "Thunder",
    "Tic Toc",
    "TikiDaddy",
    "Tinkerbell",
    "Toecutter",
    "TomCat",
    "Tool",
    "Toots",
    "Trailer Hitch",
    "Tranquilitea",
    "Treeva",
    "Triumph",
    "Tryp",
    "Tuatha",
    "Tuff (e.nuff)",
    "Tulsa",
    "Tumtetum",
    "Turnip",
    "Turtle Dove",
    "Tuxedo",
    "Twilight",
    "Twinkle Toes",
    "Twisted Cat",
    "Two-Step",
    "Uncle Dave",
    "Uncle John",
    "Urchin",
    "Vegas",
    "Verdi",
    "Vertigo",
    "Vichi Lobo",
    "Victrolla",
    "Viking",
    "Vishna",
    "Vivid",
    "Voyager",
    "Wasabi",
    "Wavelet",
    "Wee Heavy",
    "Whipped Cream",
    "Whoop D",
    "Wicked",
    "Wild Fox",
    "Wild Ginger",
    "Wingspan",
    "Wotan",
    "Wunderpants",
    "Xplorer",
    "Xtevan",
    "Xtract",
    "Yeti",
    "Zeitgeist",
    "Zero Hour",
    "biteme",
    "caramel",
    "daMongolian",
    "jedi",
    "k8",
    "longshot",
    "mindscrye",
    "natural",
    "ultra",
)
