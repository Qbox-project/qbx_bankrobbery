return {
    hitsNeeded = 13, -- The amount of powerstation needed to be hit to cause a blackout
    blackoutTimer = 10, -- The amount of minutes a blackout will take until all power comes back

    rewardTypes = {
        [1] = {
            type = "item"
        },
        [2] = {
            type = "money"
        },
    },

    lockerRewards = {
        ["tier1"] = {
            [1] = {item = "goldchain", minAmount = 5, maxAmount = 15},
        },
        ["tier2"] = {
            [1] = {item = "rolex", minAmount = 5, maxAmount = 15},
        },
        ["tier3"] = {
            [1] = {item = "goldbar", minAmount = 1, maxAmount = 2},
        },
    },

    lockerRewardsPaleto = {
        ["tier1"] = {
            [1] = {item = "goldchain", minAmount = 10, maxAmount = 20},
        },
        ["tier2"] = {
            [1] = {item = "rolex", minAmount = 10, maxAmount = 20},
        },
        ["tier3"] = {
            [1] = {item = "goldbar", minAmount = 2, maxAmount = 4},
        },
    },

    lockerRewardsPacific = {
        ["tier1"] = {
            [1] = {item = "goldbar", minAmount = 4, maxAmount = 8},
        },
        ["tier2"] = {
            [1] = {item = "goldbar", minAmount = 4, maxAmount = 8},
        },
        ["tier3"] = {
            [1] = {item = "goldbar", minAmount = 4, maxAmount = 8},
        },
    },

    cameraHits = {
        [1] = {
            type = {"police", "bank"},
            stationsToHitPolice = {1, 2, 3, 4, 5, 6},
            stationsToHitBank = {1, 2, 11}
        },
        [2] = {
            type = {"police", "bank"},
            stationsToHitPolice = {1, 2, 3, 4, 5, 6},
            stationsToHitBank = {1, 2, 11}
        },
        [3] = {
            type = {"police", "bank"},
            stationsToHitPolice = {1, 2, 3, 4, 5, 6},
            stationsToHitBank = {4, 5, 6, 8}
        },
        [4] = {
            type = {"police", "bank"},
            stationsToHitPolice = {4, 5, 6},
            stationsToHitBank = {12, 13}
        },
        [5] = {
            type = {"police", "bank"},
            stationsToHitPolice = {4, 5, 6},
            stationsToHitBank = {12, 13}
        },
        [6] = {
            type = "police",
            stationsToHitPolice = {4, 5, 6}
        },
        [7] = {
            type = "police",
            stationsToHitPolice = 3
        },
        [8] = {
            type = "police",
            stationsToHitPolice = {4, 5, 6}
        },
        [9] = {
            type = "police",
            stationsToHitPolice = {7, 8}
        },
        [10] = {
            type = "police",
            stationsToHitPolice = {7, 8}
        },
        [11] = {
            type = "police",
            stationsToHitPolice = 9
        },
        [12] = {
            type = "police",
            stationsToHitPolice = 9
        },
        [13] = {
            type = "police",
            stationsToHitPolice = 9
        },
        [14] = {
            type = "police",
            stationsToHitPolice = {9, 10}
        },
        [15] = {
            type = "police",
            stationsToHitPolice = {7, 9, 10}
        },
        [16] = {
            type = "police",
            stationsToHitPolice = {7, 9, 10}
        },
        [17] = {
            type = "police",
            stationsToHitPolice = {9, 10}
        },
        [18] = {
            type = "police",
            stationsToHitPolice = 3
        },
        [19] = {
            type = "police",
            stationsToHitPolice = {{1, 2, 3}, {9, 10}}
        },
        [20] = {
            type = "police",
            stationsToHitPolice = 10
        },
        [21] = {
            type = "police",
            stationsToHitPolice = {1, 2, 11}
        },
        [22] = {
            type = "police",
            stationsToHitPolice = {1, 2, 11}
        },
        [23] = {
            type = "police",
            stationsToHitPolice = {4, 5, 6, 8}
        },
        [24] = {
            type = "police",
            stationsToHitPolice = {12, 13}
        },
        [25] = {
            type = "police",
            stationsToHitPolice = {12, 13}
        },
    },
}