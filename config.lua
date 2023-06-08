Config = {}

Config.NotEnoughCopsNotify = true

Config.Fleeca = {
    RequiredPolice = 0,
    RequiredItems = { 'trojan_usb', 'electronickit' },
    LockerActions = {
        lockpick = { requireditem = 'lockpick', event = 'lockpick' },
        drill = { requireditem = 'drill', event = 'drill' }
    }
}

Config.BankLocations = {
    {
        label = 'Bank 1',
        camId = 21,
        Zone = {
            points = {
                vec3(308.0, -272.0, 54.0),
                vec3(320.0, -276.0, 54.0),
                vec3(315.0, -291.0, 54.0),
                vec3(303.0, -286.0, 54.0),
            },
            thickness = 6.0
        },
        Door = {
            hash = `hei_prop_heist_sec_door`,
            coords = vector3(311.15, -284.49, 54.16),
            opened = false,
            heading = {
                closed = 250.0,
                open = 160.0
            }
        },
        CashStack = {
            taken = false,
            coords = vector4(312.8111267089844, -287.506103515625, 53.99585723876953, 160.0)
        },
        Lockers = {
            { coords = vector4(314.13, -283.25, 54.14, 342.93), taken = false, action = Config.Fleeca.LockerActions.lockpick },
            { coords = vector4(315.54, -284.97, 54.14, 257.52), taken = false, action = Config.Fleeca.LockerActions.lockpick },
            { coords = vector4(311.11, -286.96, 54.14, 73.46), taken = false, action = Config.Fleeca.LockerActions.drill },
            { coords = vector4(312.65, -289.21, 54.14, 161.47), taken = false, action = Config.Fleeca.LockerActions.drill },
            { coords = vector4(314.92, -288.28, 54.14, 250.29), taken = false, action = Config.Fleeca.LockerActions.drill }
        }
    },
    {
        label = 'Legion Square',
        camId = 22,
        Zone = {
            points = {
                vec3(144.0, -1032.0, 29.0),
                vec3(157.0, -1036.0, 29.0),
                vec3(151.0, -1053.0, 29.0),
                vec3(138.0, -1046.0, 29.0),
            },
            thickness = 6.0
        },
        Door = {
            hash = `hei_prop_heist_sec_door`,
            coords = vector3(146.92, -1046.11, 29.36),
            opened = false,
            heading = {
                closed = 250.0,
                open = 160.0
            }
        },
        CashStack = {
            taken = false,
            coords = vector4(148.47442626953125, -1049.126220703125, 29.19914054870605, 160.0)
        },
        Lockers = {
            { coords = vector4(149.77, -1044.88, 29.35, 341.57), taken = false, action = Config.Fleeca.LockerActions.lockpick },
            { coords = vector4(151.22, -1046.57, 29.35, 249.04), taken = false, action = Config.Fleeca.LockerActions.lockpick },
            { coords = vector4(146.79, -1048.51, 29.35, 74.32), taken = false, action = Config.Fleeca.LockerActions.drill },
            { coords = vector4(148.41, -1050.89, 29.35, 161.06), taken = false, action = Config.Fleeca.LockerActions.drill },
            { coords = vector4(150.33, -1049.84, 29.35, 253.61), taken = false, action = Config.Fleeca.LockerActions.drill }
        }
    },
    {
        label = 'Hawick Ave',
        camId = 23,
        Zone = {
            points = {
                vec3(-356.0, -42.0, 49.0),
                vec3(-342.0, -47.0, 49.0),
                vec3(-349.0, -65.0, 49.0),
                vec3(-363.0, -61.0, 49.0),
            },
            thickness = 6.0
        },
        Door = {
            hash = `hei_prop_heist_sec_door`,
            coords = vector3(-353.82, -55.37, 49.03),
            opened = false,
            heading = {
                closed = 250.0,
                open = 160.0
            }
        },
        CashStack = {
            taken = false,
            coords = vector4(-352.20947265625, -58.33846664428711, 48.86764144897461, 160.0)
        },
        Lockers = {
            { coords = vector4(-351.05, -54.11, 49.01, 341.55), taken = false, action = Config.Fleeca.LockerActions.lockpick },
            { coords = vector4(-349.5, -55.72, 49.01, 251.98), taken = false, action = Config.Fleeca.LockerActions.lockpick },
            { coords = vector4(-353.88, -57.72, 49.01, 71.24), taken = false, action = Config.Fleeca.LockerActions.drill },
            { coords = vector4(-352.23, -60.03, 49.01, 164.16), taken = false, action = Config.Fleeca.LockerActions.drill },
            { coords = vector4(-350.07, -59.07, 49.01, 252.18), taken = false, action = Config.Fleeca.LockerActions.drill }
        }
    },
    {
        label = 'Del Perro Blvd',
        camId = 24,
        Zone = {
            points = {
                vec3(-1222.0, -329.0, 38.0),
                vec3(-1206.0, -321.0, 38.0),
                vec3(-1198.0, -338.0, 38.0),
                vec3(-1213.0, -346.0, 38.0),
            },
            thickness = 6.0
        },
        Door = {
            hash = `hei_prop_heist_sec_door`,
            coords = vector3(-1210.77, -336.57, 37.78),
            opened = false,
            heading = {
                closed = 296.0,
                open = 206.0
            }
        },
        CashStack = {
            taken = false,
            coords = vector4(-1207.4844970703125, -337.44573974609375, 37.61210250854492, 207.0)
        },
        Lockers = {
            { coords = vector4(-1209.74, -333.63, 37.76, 30.0), taken = false, action = Config.Fleeca.LockerActions.lockpick },
            { coords = vector4(-1207.43, -333.78, 37.76, 296.86), taken = false, action = Config.Fleeca.LockerActions.lockpick },
            { coords = vector4(-1209.05, -338.34, 37.76, 123.7), taken = false, action = Config.Fleeca.LockerActions.drill },
            { coords = vector4(-1206.21, -338.68, 37.76, 210.89), taken = false, action = Config.Fleeca.LockerActions.drill },
            { coords = vector4(-1205.57, -336.43, 37.76, 296.59), taken = false, action = Config.Fleeca.LockerActions.drill }
        }
    },
    {
        label = 'Great Ocean Hwy',
        camId = 25,
        Zone = {
            points = {
                vec3(-2973.0, 471.0, 18.0),
                vec3(-2946.0, 468.0, 18.0),
                vec3(-2943.0, 491.0, 18.0),
                vec3(-2975.0, 492.0, 18.0),
            },
            thickness = 9.0
        },
        Door = {
            hash = `hei_prop_heist_sec_door`,
            coords = vector3(-2956.55, 481.74, 15.69),
            opened = false,
            heading = {
                closed = 357.0,
                open = 267.0
            }
        },
        CashStack = {
            taken = false,
            coords = vector4(-2954.17, 484.53, 15.52, 267.54)
        },
        Lockers = {
            { coords = vector4(-2958.58, 483.94, 15.68, 92.44), taken = false, action = Config.Fleeca.LockerActions.lockpick },
            { coords = vector4(-2957.46, 485.96, 15.68, 357.69), taken = false, action = Config.Fleeca.LockerActions.lockpick },
            { coords = vector4(-2953.97, 482.4, 15.68, 177.3), taken = false, action = Config.Fleeca.LockerActions.drill },
            { coords = vector4(-2952.49, 484.34, 15.68, 268.82), taken = false, action = Config.Fleeca.LockerActions.drill },
            { coords = vector4(-2954.19, 486.39, 15.68, 358.71), taken = false, action = Config.Fleeca.LockerActions.drill }
        }
    },
    {
        label = 'East',
        camId = 25,
        Zone = {
            points = {
                vec3(1171.0, 2718.0, 38.25),
                vec3(1182.0, 2717.0, 38.25),
                vec3(1182.0, 2701.0, 38.25),
                vec3(1170.0, 2701.0, 38.25),
            },
            thickness = 5.75
        },
        Door = {
            hash = `hei_prop_heist_sec_door`,
            coords = vector3(1175.96, 2712.87, 38.09),
            opened = false,
            heading = {
                closed = 90.0,
                open = 2.0
            }
        },
        CashStack = {
            taken = false,
            coords = vector4(1173.4801025390625, 2715.168212890625, 37.91910171508789, 0.0)
        },
        Lockers = {
            { coords = vector4(1173.8, 2710.72, 38.07, 180.15), taken = false, action = Config.Fleeca.LockerActions.lockpick },
            { coords = vector4(1171.78, 2711.79, 38.07, 88.2), taken = false, action = Config.Fleeca.LockerActions.lockpick },
            { coords = vector4(1175.18, 2715.35, 38.07, 275.77), taken = false, action = Config.Fleeca.LockerActions.drill },
            { coords = vector4(1173.26, 2716.83, 38.07, 358.18), taken = false, action = Config.Fleeca.LockerActions.drill },
            { coords = vector4(1171.21, 2715.07, 38.07, 95.88), taken = false, action = Config.Fleeca.LockerActions.drill }
        }
    }
}

Config.PaletoBank = {
    label = 'Blaine County Savings Bank',
    coords = vector3(-105.61, 6472.03, 31.62),
    camId = 26,
    Zone = {
        points = {
            vec3(-126.59999847412, 6471.6000976562, 32.5),
            vec3(-102.59999847412, 6447.5, 32.5),
            vec3(-84.5, 6465.0, 32.5),
            vec3(-108.5, 6489.5, 32.5),
        },
        thickness = 11.0
    },
    Door = {
        hash = `v_ilev_cbankvauldoor01`,
        opened = false
    }
}

Config.PacificBank = {
    label = 'Pacific Standard',
    coords = vector3(261.95, 223.11, 106.28),
    camId = 26,
    Zone = {
        points = {
            vec(213.53, 204.9, 105.49),
            vec(234.97, 259.44, 105.45),
            vec3(292.0, 234.0, 109.0),
            vec3(272.0, 186.0, 109.0),
        },
        thickness = 38.25
    }
}