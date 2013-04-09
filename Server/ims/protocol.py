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
Protocol bits
"""

__all__ = [
]

from twisted.python.filepath import FilePath
from twisted.web import http

from klein import route

from ims.store import Storage
from ims.data import Incident, JSON, to_json, from_json_io
from ims.sauce import url_for, set_content_type
from ims.sauce import http_sauce
from ims.sauce import HeaderName, ContentType


protocol_version = "0.0"


@route("/ping/", methods=("GET",))
@http_sauce
def ping(request):
    set_content_type(request, ContentType.JSON)
    return to_json("ack")


@route("/rangers/", methods=("GET",))
@http_sauce
def list_rangers(request):
    set_content_type(request, ContentType.JSON)
    return to_json(tuple(
        {
            "handle": handle,
            "name": None,
        }
        for handle in allRangers
    ))


@route("/incident_types/", methods=("GET",))
@http_sauce
def list_incident_types(request):
    set_content_type(request, ContentType.JSON)
    return to_json((
        "Admin",
        "Art",
        "Echelon",
        "Eviction",
        "Fire",
        "Gate",
        "Green Dot",
        "HQ",
        "Law Enforcement",
        "Medical",
        "Mental Health",
        "SITE",
        "Staff",
        "Theme Camp",
        "Vehicle",

        "Junk",
    ))


@route("/incidents/", methods=("GET",))
@http_sauce
def list_incidents(request):
    set_content_type(request, ContentType.JSON)
    return to_json(tuple(storage().list_incidents()))


@route("/incidents/<number>", methods=("GET",))
@http_sauce
def get_incident(request, number):
    import time
    time.sleep(0.3)
    set_content_type(request, ContentType.JSON)
    return storage().read_incident_with_number_raw(number)


@route("/incidents/<number>", methods=("POST",))
@http_sauce
def edit_incident(request, number):
    number = int(number)
    incident = storage().read_incident_with_number(number)

    edits_json = from_json_io(request.content)
    edits = Incident.from_json(edits_json, number=number, validate=False)

    for key in edits_json.keys():
        if key == "report_entries":
            incident.report_entries += edits.report_entries
        elif key == "location_name":
            incident.location.name = edits.location.name
        elif key == "location_address":
            incident.location.address = edits.location.address
        elif key == "ranger_handles":
            incident.rangers = edits.rangers
        else:
            attr_name = JSON.lookupByValue(key).name
            setattr(incident, attr_name, getattr(edits, attr_name))

    storage().write_incident(incident)

    # FIXME: created is only correct for new resources
    request.setResponseCode(http.CREATED)

    return "";


@route("/incidents/", methods=("POST",))
@http_sauce
def new_incident(request):
    store = storage()

    incident = Incident.from_json_io(request.content, number=store.next_incident_number())
    store.write_incident(incident)

    request.setResponseCode(http.CREATED)

    request.setHeader(
        HeaderName.location.value,
        url_for(request, "get_incident", {"number": incident.number})
    )

    return "";


def storage():
    global _storage
    if _storage is None:
        _storage = Storage(FilePath(__file__).parent().parent().child("data"))
        _storage.provision()
    return _storage
_storage = None



allRangers = (
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

    "Intercept",
    "Khaki",
    "Operator",
    "Operations Manager",
    "Officer of the Day",
    "Logistics Managers",
    "Personnel Manager",
    "Captain Hook",
    "ESD 911 Dispatch",
    "DPW Dispatch",
)
