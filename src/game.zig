const std = @import("std");
const builtin = @import("builtin");

pub const PlayerCount = 4;
const StartingCoins = 3;
const LoRollEstablishmentPileCount = 5;
const HiRollEstablishmentPileCount = 5;
const MajorEstablishmentPileCount = 2;

//const verboseMode = (builtin.mode == builtin.Mode.Debug);
const verboseMode = false;

pub const BotCode = struct {
    shouldRollTwoDiceFunc: fn (*GameState) bool,
    getCardToPurchaseFunc: fn (*GameState) ?PurchasableCard,

    shouldActivateHarborFunc: fn (*GameState) bool,
    shouldReroll: fn (*GameState) bool,
    getPlayerToStealCoinsFrom: fn (*GameState, u32) usize,
};

const ActivationTurn = enum {
    Any,
    You,
    Els,
};

pub const CardIcon = enum {
    Wheat,
    Cow,
    Cog,
    Box,
    Cup,
    Factory,
    Tower,
    Boat,
    Briefcase,
};

pub const CardType = enum {
    Landmark,
    Establishment,
};

const MultiplyType = enum {
    CardIcon,
    EstablishmentType,
};

const CoinMultiplier = struct {
    type: MultiplyType,
    index: usize,

    fn initIcon(icon: CardIcon) CoinMultiplier {
        return CoinMultiplier{
            .type = MultiplyType.CardIcon,
            .index = @enumToInt(icon),
        };
    }

    fn initEst(estType: EstablishmentType) CoinMultiplier {
        return CoinMultiplier{
            .type = MultiplyType.EstablishmentType,
            .index = @enumToInt(estType),
        };
    }
};

pub const PurchasableCard = struct {
    type: CardType,
    index: usize,
};

// City Hall?
pub const Landmark = enum {
    Harbor,
    TrainStation,
    ShoppingMall,
    AmusementPark,
    RadioTower,
    Airport,
};

const EstablishmentDeck = enum {
    LowCost,
    HighCost,
    Major,
};

pub const EstablishmentType = enum {
    // Primary Industry (Blue)
    WheatField,
    Ranch,
    FlowerOrchard,
    Forest,
    Vineyard,
    MackerelBoat,
    Mine,
    AppleOrchard,
    TunaBoat,

    // Secondary Industry (Green)
    Bakery,
    ConvenienceStore,
    FlowerShop,
    CheeseFactory,
    FurnitureFactory,
    FarmersMarket,
    FoodWarehouse,

    // Restaurant (Red)
    SushiBar,
    Cafe,
    PizzaJoint,
    HamburgerStand,
    FamilyRestaurant,

    // Major Establishment (Purple)
    Stadium,
    TVStation,
    BusinessCentre,
    Publisher,
    TaxOffice,
};

const Establishment = struct {
    type: EstablishmentType,
    cost: i32,
    activationMin: u32,
    activationMax: u32,
    activationTurn: ActivationTurn,
    coinsGiven: i32,
    icon: CardIcon,
    multiplier: ?CoinMultiplier,

    pub fn init(cost: i32, actMin: u32, actMax: u32, turn: ActivationTurn, coinsGiven: i32, icon: CardIcon, estType: EstablishmentType, multiplier: ?CoinMultiplier) Establishment {
        return Establishment{
            .type = estType,
            .cost = cost,
            .activationMin = actMin,
            .activationMax = actMax,
            .activationTurn = turn,
            .coinsGiven = coinsGiven,
            .icon = icon,
            .multiplier = multiplier,
        };
    }

    fn deck(self: *const Establishment) EstablishmentDeck {
        if (self.icon == CardIcon.Tower) return EstablishmentDeck.Major;
        if (self.activationMin <= 6) return EstablishmentDeck.LowCost;
        return EstablishmentDeck.HighCost;
    }
};

pub const allEstablishments: [@memberCount(EstablishmentType)]Establishment = [_]Establishment{
    Establishment.init(1, 1, 1, ActivationTurn.Any, 1, CardIcon.Wheat, EstablishmentType.WheatField, null),
    Establishment.init(1, 2, 2, ActivationTurn.Any, 1, CardIcon.Cow, EstablishmentType.Ranch, null),
    Establishment.init(2, 4, 4, ActivationTurn.Any, 1, CardIcon.Wheat, EstablishmentType.FlowerOrchard, null),
    Establishment.init(3, 5, 5, ActivationTurn.Any, 1, CardIcon.Cog, EstablishmentType.Forest, null),
    Establishment.init(3, 7, 7, ActivationTurn.Any, 3, CardIcon.Wheat, EstablishmentType.Vineyard, null),
    Establishment.init(2, 8, 8, ActivationTurn.Any, 3, CardIcon.Boat, EstablishmentType.MackerelBoat, null),
    Establishment.init(6, 9, 9, ActivationTurn.Any, 5, CardIcon.Cog, EstablishmentType.Mine, null),
    Establishment.init(3, 10, 10, ActivationTurn.Any, 3, CardIcon.Wheat, EstablishmentType.AppleOrchard, null),
    Establishment.init(5, 12, 14, ActivationTurn.Any, 0, CardIcon.Boat, EstablishmentType.TunaBoat, null),

    Establishment.init(1, 2, 3, ActivationTurn.You, 1, CardIcon.Box, EstablishmentType.Bakery, null),
    Establishment.init(2, 4, 4, ActivationTurn.You, 3, CardIcon.Box, EstablishmentType.ConvenienceStore, null),
    Establishment.init(1, 6, 6, ActivationTurn.You, 1, CardIcon.Box, EstablishmentType.FlowerShop, CoinMultiplier.initEst(EstablishmentType.FlowerOrchard)),
    Establishment.init(5, 7, 7, ActivationTurn.You, 3, CardIcon.Factory, EstablishmentType.CheeseFactory, CoinMultiplier.initIcon(CardIcon.Cow)),
    Establishment.init(3, 8, 8, ActivationTurn.You, 3, CardIcon.Factory, EstablishmentType.FurnitureFactory, CoinMultiplier.initIcon(CardIcon.Cog)),
    Establishment.init(2, 11, 12, ActivationTurn.You, 2, CardIcon.Factory, EstablishmentType.FarmersMarket, CoinMultiplier.initIcon(CardIcon.Wheat)),
    Establishment.init(2, 12, 13, ActivationTurn.You, 2, CardIcon.Factory, EstablishmentType.FoodWarehouse, CoinMultiplier.initIcon(CardIcon.Cup)),

    Establishment.init(4, 1, 1, ActivationTurn.Els, 3, CardIcon.Cup, EstablishmentType.SushiBar, null),
    Establishment.init(2, 3, 3, ActivationTurn.Els, 1, CardIcon.Cup, EstablishmentType.Cafe, null),
    Establishment.init(1, 7, 7, ActivationTurn.Els, 1, CardIcon.Cup, EstablishmentType.PizzaJoint, null),
    Establishment.init(1, 8, 8, ActivationTurn.Els, 1, CardIcon.Cup, EstablishmentType.HamburgerStand, null),
    Establishment.init(3, 9, 10, ActivationTurn.Els, 2, CardIcon.Cup, EstablishmentType.FamilyRestaurant, null),

    Establishment.init(6, 6, 6, ActivationTurn.You, 0, CardIcon.Tower, EstablishmentType.Stadium, null),
    Establishment.init(7, 6, 6, ActivationTurn.You, 0, CardIcon.Tower, EstablishmentType.TVStation, null),
    Establishment.init(8, 6, 6, ActivationTurn.You, 0, CardIcon.Tower, EstablishmentType.BusinessCentre, null),
    Establishment.init(5, 7, 7, ActivationTurn.You, 0, CardIcon.Tower, EstablishmentType.Publisher, null),
    Establishment.init(4, 8, 9, ActivationTurn.You, 0, CardIcon.Tower, EstablishmentType.TaxOffice, null),

    // TODO: Extras
    //Establishment.init(0, 2, 2, ActivationTurn.You, 2, CardIcon.Box, EstablishmentType.GeneralStore, null), // TODO: Requires 0 or 1 built landmarks
    //Establishment.init(3, 5, 5, ActivationTurn.Els, 5, CardIcon.Cup, EstablishmentType.FrenchRestaurant, null), // TODO: Requires the opponent as at least 2 landmarks built
    //Establishment.init(-5, 5, 6, ActivationTurn.You, -2, CardIcon.Briefcase, EstablishmentType.LoanOffice, null), // TODO: Only lose coins if you can (IE never get negative coins)
    //Establishment.init(2, 3, 4, ActivationTurn.Any, 1, CardIcon.Wheat, EstablishmentType.CornField, null), // TODO: Requires 0 or 1 landmarks
    //Establishment.init(2, 4, 4, ActivationTurn.You, 0, CardIcon.Briefcase, EstablishmentType.DemolitionCompany, null), // TODO: You may demolish a built landmark to get 8 coins
    //Establishment.init(2, 9, 10, ActivationTurn.You, 0, CardIcon.Briefcase, EstablishmentType.MovingCompany, null), // TODO: Get 4 coins if you give a non-tower establishment to an opponent
    //Establishment.init(5, 11, 11, ActivationTurn.You, 1, CardIcon.Factory, EstablishmentType.SodaBottlingPlant, CardIcon.Cup), // TODO: Also multiply by the number of cups owned by all other players (IE all players in total)
    //Establishment.init(3, 9, 9, AcitvationTurn.You, 6, CardIcon.Factory, EstablishmentType.Winery, null), // TODO: Multiply by the number of vineyards you own, then close for renovation
    //Establishment.init(4, 12, 14, ActivationTurn.Els, 0, CardIcon.Cup, EstablishmentType.PrivateClub, null), // TODO: Require that the other player has at least 3 built landmarks, take all their money

    //Establishment.init(4, 8, 8, ActivationTurn.You, 0, CardIcon.Tower, EstablishmentType.RenovationCompany, null), // TODO: Close all copies of any 1 establishment in play for renovation. Take 1 coin from each opponent for each establishment they own that was closed this way
    //Establishment.init(3, 11, 13, ActivationTurn.You, 0, CardIcon.Tower, EstablishmentType.Park, null), // TODO: Redistribute all players coins as evenly as possible, making up any difference with coins from the bank
    //Establishment.init(7, 10, 10, ActivationTurn.You, 0, CardIcon.Tower, EstablishmentType.ExhibitHall, null), // TODO: May activate 1 of your non-tower establishments instead of this one. If you do, return this establishment to the supply
    //Establishment.init(1, 10, 10, ActivationTurn.You, 0, CardIcon.Tower, EstablishmentType.TechStartup, null), // TODO: At the end of each of your turns, you may add 1 coin to this card. When activated, take coins from each opponent equal to the amount on this card
};

fn enumToEstablishment(estType: EstablishmentType) *const Establishment {
    return &allEstablishments[@enumToInt(estType)];
}

const GamePlayerState = struct {
    coins: i32,
    landmarks: [@memberCount(Landmark)]bool,

    establishmentsAnyTurn: std.ArrayList(*const Establishment),
    establishmentsYourTurn: std.ArrayList(*const Establishment),
    establishmentsOtherTurns: std.ArrayList(*const Establishment),

    totalCoinsEarned: [@memberCount(EstablishmentType)]i64,

    pub fn addEstablishment(self: *@This(), est: *const Establishment) !void {
        self.coins -= est.cost;
        try switch (est.activationTurn) {
            ActivationTurn.Any => self.establishmentsAnyTurn.append(est),
            ActivationTurn.You => self.establishmentsYourTurn.append(est),
            ActivationTurn.Els => self.establishmentsOtherTurns.append(est),
        };
    }
};

const EstablishmentPurchasingPile = struct {
    establishment: *const Establishment,
    count: u32,
};

pub const GameState = struct {
    currentTurn: u32,
    currentPlayerIndex: u32,
    rng: *std.rand.Xoroshiro128,
    players: [PlayerCount]GamePlayerState,
    alloc: *std.mem.Allocator,

    establishmentPurchasePiles: [@memberCount(EstablishmentType)]u8,

    loEstablishmentDeck: std.ArrayList(*const Establishment),
    hiEstablishmentDeck: std.ArrayList(*const Establishment),
    majorEstablishmentDeck: std.ArrayList(*const Establishment),

    bot: BotCode,

    pub fn init(alloc: *std.mem.Allocator, rng: *std.rand.Xoroshiro128, bot: BotCode) !GameState {
        for (allEstablishments) |est, estIndex| {
            if (estIndex != @enumToInt(est.type)) {
                std.debug.panic("Establishment {} expected at index {}, found at index {}!", est.type, @enumToInt(est.type), estIndex);
            }
        }

        var result = GameState{
            .currentTurn = 0,
            .currentPlayerIndex = 0,
            .rng = rng,
            .players = [_]GamePlayerState{undefined} ** PlayerCount,
            .alloc = alloc,
            .establishmentPurchasePiles = [_]u8{0} ** @memberCount(EstablishmentType),
            .loEstablishmentDeck = std.ArrayList(*const Establishment).init(alloc),
            .hiEstablishmentDeck = std.ArrayList(*const Establishment).init(alloc),
            .majorEstablishmentDeck = std.ArrayList(*const Establishment).init(alloc),
            .bot = bot,
        };

        try addEstablishmentToDeck(&result.loEstablishmentDeck, 6, EstablishmentType.WheatField);
        try addEstablishmentToDeck(&result.loEstablishmentDeck, 6, EstablishmentType.Ranch);
        try addEstablishmentToDeck(&result.loEstablishmentDeck, 6, EstablishmentType.FlowerOrchard);
        try addEstablishmentToDeck(&result.loEstablishmentDeck, 6, EstablishmentType.Forest);
        try addEstablishmentToDeck(&result.loEstablishmentDeck, 6, EstablishmentType.Bakery);
        try addEstablishmentToDeck(&result.loEstablishmentDeck, 6, EstablishmentType.ConvenienceStore);
        try addEstablishmentToDeck(&result.loEstablishmentDeck, 6, EstablishmentType.FlowerShop);
        try addEstablishmentToDeck(&result.loEstablishmentDeck, 6, EstablishmentType.SushiBar);
        try addEstablishmentToDeck(&result.loEstablishmentDeck, 6, EstablishmentType.Cafe);
        result.rng.random.shuffle(*const Establishment, result.loEstablishmentDeck.toSlice());

        try addEstablishmentToDeck(&result.hiEstablishmentDeck, 6, EstablishmentType.Vineyard);
        try addEstablishmentToDeck(&result.hiEstablishmentDeck, 6, EstablishmentType.MackerelBoat);
        try addEstablishmentToDeck(&result.hiEstablishmentDeck, 6, EstablishmentType.Mine);
        try addEstablishmentToDeck(&result.hiEstablishmentDeck, 6, EstablishmentType.AppleOrchard);
        try addEstablishmentToDeck(&result.hiEstablishmentDeck, 6, EstablishmentType.TunaBoat);
        try addEstablishmentToDeck(&result.hiEstablishmentDeck, 6, EstablishmentType.CheeseFactory);
        try addEstablishmentToDeck(&result.hiEstablishmentDeck, 6, EstablishmentType.FurnitureFactory);
        try addEstablishmentToDeck(&result.hiEstablishmentDeck, 6, EstablishmentType.FarmersMarket);
        try addEstablishmentToDeck(&result.hiEstablishmentDeck, 6, EstablishmentType.FoodWarehouse);
        try addEstablishmentToDeck(&result.hiEstablishmentDeck, 6, EstablishmentType.PizzaJoint);
        try addEstablishmentToDeck(&result.hiEstablishmentDeck, 6, EstablishmentType.HamburgerStand);
        try addEstablishmentToDeck(&result.hiEstablishmentDeck, 6, EstablishmentType.FamilyRestaurant);
        result.rng.random.shuffle(*const Establishment, result.hiEstablishmentDeck.toSlice());

        try addEstablishmentToDeck(&result.majorEstablishmentDeck, 4, EstablishmentType.Stadium);
        try addEstablishmentToDeck(&result.majorEstablishmentDeck, 4, EstablishmentType.TVStation);
        try addEstablishmentToDeck(&result.majorEstablishmentDeck, 4, EstablishmentType.Publisher);
        try addEstablishmentToDeck(&result.majorEstablishmentDeck, 4, EstablishmentType.TaxOffice);
        result.rng.random.shuffle(*const Establishment, result.majorEstablishmentDeck.toSlice());

        var pid: usize = 0;
        while (pid < PlayerCount) {
            defer pid += 1;

            result.players[pid].coins = StartingCoins;
            result.players[pid].landmarks = [_]bool{false} ** @memberCount(Landmark);
            result.players[pid].establishmentsAnyTurn = std.ArrayList(*const Establishment).init(alloc);
            result.players[pid].establishmentsYourTurn = std.ArrayList(*const Establishment).init(alloc);
            result.players[pid].establishmentsOtherTurns = std.ArrayList(*const Establishment).init(alloc);
            result.players[pid].totalCoinsEarned = [_]i64{0} ** @memberCount(EstablishmentType);

            try result.players[pid].establishmentsAnyTurn.append(enumToEstablishment(EstablishmentType.WheatField));
            try result.players[pid].establishmentsYourTurn.append(enumToEstablishment(EstablishmentType.Bakery));
        }

        var i: usize = 0;
        while (i < LoRollEstablishmentPileCount) {
            result.createEstablishmentPile(&result.loEstablishmentDeck);
            i += 1;
        }

        i = 0;
        while (i < HiRollEstablishmentPileCount) {
            result.createEstablishmentPile(&result.hiEstablishmentDeck);
            i += 1;
        }

        i = 0;
        while (i < MajorEstablishmentPileCount) {
            result.createEstablishmentPile(&result.majorEstablishmentDeck);
            i += 1;
        }
        return result;
    }

    fn addEstablishmentToDeck(deck: *std.ArrayList(*const Establishment), count: usize, estType: EstablishmentType) !void {
        const est = &allEstablishments[@enumToInt(estType)];
        var i: usize = 0;
        while (i < count) {
            try deck.append(est);
            i += 1;
        }
    }

    fn createEstablishmentPile(self: *GameState, deck: *std.ArrayList(*const Establishment)) void {
        while (deck.len > 0) {
            const est = deck.pop();
            const pileSize = &self.establishmentPurchasePiles[@enumToInt(est.type)];
            if (pileSize.* > 0) {
                pileSize.* += 1;
                continue;
            }

            pileSize.* = 1;
            break;
        }
    }

    fn print(self: *GameState) void {
        std.debug.warn("Current Turn: {}\n", self.currentTurn);
        std.debug.warn("Current Player: {}\n", self.currentPlayerIndex);
        std.debug.warn("Low-cost establishment deck has {} cards remaining\n", self.loEstablishmentDeck.count());
        std.debug.warn("High-cost establishment deck has {} cards remaining\n", self.hiEstablishmentDeck.count());
        std.debug.warn("Major establishment deck has {} cards remaining\n", self.majorEstablishmentDeck.count());

        std.debug.warn("Establishment purchasing piles: ");
        for (self.establishmentPurchasePiles) |pileHeight, establishmentTypeIndex| {
            if (pileHeight == 0) continue;
            const est = allEstablishments[establishmentTypeIndex];
            std.debug.warn("{}x{}, ", pileHeight, @tagName(est.type));
        }
        std.debug.warn("\n");

        for (self.players) |player, playerIndex| {
            std.debug.warn("Player {}: Coins={}, Landmarks=", playerIndex, player.coins);
            for (player.landmarks) |landmarkPurchased| {
                std.debug.warn("{}/", landmarkPurchased);
            }
            std.debug.warn("\n");
            var playerEstablishmentCounts = [_]u8{0} ** @memberCount(EstablishmentType);
            for (player.establishmentsAnyTurn.toSliceConst()) |est| {
                playerEstablishmentCounts[@enumToInt(est.type)] += 1;
            }
            for (player.establishmentsYourTurn.toSliceConst()) |est| {
                playerEstablishmentCounts[@enumToInt(est.type)] += 1;
            }
            for (player.establishmentsOtherTurns.toSliceConst()) |est| {
                playerEstablishmentCounts[@enumToInt(est.type)] += 1;
            }
            for (playerEstablishmentCounts) |estCount, estType| {
                if (estCount == 0) continue;
                std.debug.warn("{}x {}, ", estCount, @tagName(@intToEnum(EstablishmentType, @intCast(@TagType(EstablishmentType), estType))));
            }
            std.debug.warn("\n");
        }
    }

    fn rollDie(rng: *std.rand.Random) u32 {
        return 1 + rng.uintAtMost(u32, 5);
    }

    pub fn playTurn(state: *GameState) !bool {
        state.currentTurn += 1;
        const currentPlayer = &state.players[state.currentPlayerIndex];

        var rerolled = false;
        var rolledDoubles: bool = undefined;
        var rolledValue: u32 = undefined;
        while (true) {
            rolledDoubles = false;
            rolledValue = rollDie(&state.rng.random);
            var rolledDice: u32 = 1;
            if (currentPlayer.landmarks[@enumToInt(Landmark.TrainStation)] and state.bot.shouldRollTwoDiceFunc(state)) {
                const secondRolledValue = rollDie(&state.rng.random);
                if (secondRolledValue == rolledValue) {
                    rolledDoubles = true;
                }
                rolledValue += secondRolledValue;
                rolledDice = 2;

                if ((rolledValue >= 10) and (currentPlayer.landmarks[@enumToInt(Landmark.Harbor)]) and state.bot.shouldActivateHarborFunc(state)) {
                    rolledValue += 2;
                }
            }
            if (verboseMode) {
                std.debug.warn("Player {} rolled {} dice and got {}\n", state.currentPlayerIndex, rolledDice, rolledValue);
            }

            if (rerolled or !currentPlayer.landmarks[@enumToInt(Landmark.RadioTower)] or !state.bot.shouldReroll(state)) {
                break;
            }
            rerolled = true;
        }

        // Activate red cards
        {
            var ownerIndex = (state.currentPlayerIndex + 1) % PlayerCount;
            while (ownerIndex != state.currentPlayerIndex) {
                defer ownerIndex = (ownerIndex + 1) % PlayerCount;

                const owner = &state.players[ownerIndex];
                for (owner.establishmentsOtherTurns.toSliceConst()) |est| {
                    if ((rolledValue < est.activationMin) or (rolledValue > est.activationMax)) {
                        continue;
                    }
                    if ((est.type == EstablishmentType.SushiBar) and !owner.landmarks[@enumToInt(Landmark.Harbor)]) {
                        continue;
                    }

                    var coinsRequestedByEstablishment = est.coinsGiven;
                    // NOTE: Technically we should also check (est.icon == CardIcon.Cup) but that should always be true
                    if (owner.landmarks[@enumToInt(Landmark.ShoppingMall)]) {
                        coinsRequestedByEstablishment += 1;
                    }
                    const coinsToSteal = std.math.min(coinsRequestedByEstablishment, currentPlayer.coins);
                    currentPlayer.coins -= coinsToSteal;
                    owner.coins += coinsToSteal;
                    owner.totalCoinsEarned[@enumToInt(est.type)] += coinsToSteal;
                    if (verboseMode) {
                        std.debug.warn("Activate player {}'s {} to steal {} coins\n", ownerIndex, est.type, coinsToSteal);
                    }
                }
            }
        }

        // Activate green cards
        for (currentPlayer.establishmentsYourTurn.toSliceConst()) |est| {
            if ((rolledValue < est.activationMin) or (rolledValue > est.activationMax)) {
                continue;
            }
            var coinsToGive = est.coinsGiven;
            if (est.multiplier) |multiplier| {
                var multiplyFactor: i32 = 0;
                switch (multiplier.type) {
                    MultiplyType.CardIcon => {
                        const multiplyIcon = @intToEnum(CardIcon, @intCast(@TagType(CardIcon), multiplier.index));
                        for (currentPlayer.establishmentsAnyTurn.toSliceConst()) |multiplyEst| {
                            if (multiplyEst.icon == multiplyIcon) multiplyFactor += 1;
                        }
                        for (currentPlayer.establishmentsYourTurn.toSliceConst()) |multiplyEst| {
                            if (multiplyEst.icon == multiplyIcon) multiplyFactor += 1;
                        }
                        for (currentPlayer.establishmentsOtherTurns.toSliceConst()) |multiplyEst| {
                            if (multiplyEst.icon == multiplyIcon) multiplyFactor += 1;
                        }
                    },
                    MultiplyType.EstablishmentType => {
                        const multiplyType = @intToEnum(EstablishmentType, @intCast(@TagType(EstablishmentType), multiplier.index));
                        for (currentPlayer.establishmentsAnyTurn.toSliceConst()) |multiplyEst| {
                            if (multiplyEst.type == multiplyType) multiplyFactor += 1;
                        }
                        for (currentPlayer.establishmentsYourTurn.toSliceConst()) |multiplyEst| {
                            if (multiplyEst.type == multiplyType) multiplyFactor += 1;
                        }
                        for (currentPlayer.establishmentsOtherTurns.toSliceConst()) |multiplyEst| {
                            if (multiplyEst.type == multiplyType) multiplyFactor += 1;
                        }
                    },
                }
                coinsToGive *= multiplyFactor;
            }
            if ((est.icon == CardIcon.Box) and currentPlayer.landmarks[@enumToInt(Landmark.ShoppingMall)]) {
                coinsToGive += 1;
            }
            if (verboseMode) {
                std.debug.warn("Activate player {}'s {} for {} coins\n", state.currentPlayerIndex, est.type, est.coinsGiven);
            }
            currentPlayer.coins += coinsToGive;
            currentPlayer.totalCoinsEarned[@enumToInt(est.type)] += coinsToGive;
        }

        // Activate blue cards
        var tunaBoatCoins = rollDie(&state.rng.random) + rollDie(&state.rng.random);
        for (state.players) |player, pid| {
            for (player.establishmentsAnyTurn.toSliceConst()) |est| {
                if ((rolledValue < est.activationMin) or (rolledValue > est.activationMax)) {
                    continue;
                }
                if (((est.type == EstablishmentType.MackerelBoat) or (est.type == EstablishmentType.TunaBoat)) and !currentPlayer.landmarks[@enumToInt(Landmark.Harbor)]) {
                    continue;
                }
                if (verboseMode) {
                    std.debug.warn("Activate player {}'s {} for {} coins\n", pid, est.type, est.coinsGiven);
                }
                var coinsToGive = est.coinsGiven;
                if (est.type == EstablishmentType.TunaBoat) {
                    coinsToGive += @intCast(i32, tunaBoatCoins);
                }
                currentPlayer.coins += coinsToGive;
                currentPlayer.totalCoinsEarned[@enumToInt(est.type)] += coinsToGive;
            }
        }

        // Activate purple cards
        for (currentPlayer.establishmentsYourTurn.toSliceConst()) |est| {
            if ((rolledValue < est.activationMin) or (rolledValue > est.activationMax)) {
                continue;
            }
            switch (est.type) {
                EstablishmentType.Stadium => {
                    for (state.players) |*player, pid| {
                        if (pid == state.currentPlayerIndex) continue;
                        const coinsToSteal = std.math.min(2, player.coins);
                        player.coins -= coinsToSteal;
                        currentPlayer.coins += coinsToSteal;
                        currentPlayer.totalCoinsEarned[@enumToInt(est.type)] += coinsToSteal;
                    }
                },
                EstablishmentType.TVStation => {
                    const stealPid = state.bot.getPlayerToStealCoinsFrom(state, 5);
                    const victim = &state.players[stealPid];
                    var coinsToSteal = std.math.min(victim.coins, 5);
                    victim.coins -= coinsToSteal;
                    currentPlayer.coins += coinsToSteal;
                    currentPlayer.totalCoinsEarned[@enumToInt(est.type)] += coinsToSteal;
                },
                EstablishmentType.BusinessCentre => {}, // TODO: Trade a non-major establishment with another player
                EstablishmentType.Publisher => {
                    for (state.players) |*player, pid| {
                        if (pid == state.currentPlayerIndex) continue;
                        var coinsToSteal: i32 = 0;
                        for (player.establishmentsOtherTurns.toSliceConst()) |e| {
                            if (e.icon == CardIcon.Cup) coinsToSteal += 1;
                        }
                        for (player.establishmentsYourTurn.toSliceConst()) |e| {
                            if (e.icon == CardIcon.Box) coinsToSteal += 1;
                        }
                        coinsToSteal = std.math.min(coinsToSteal, player.coins);
                        player.coins -= coinsToSteal;
                        currentPlayer.coins += coinsToSteal;
                        currentPlayer.totalCoinsEarned[@enumToInt(est.type)] += coinsToSteal;
                    }
                },
                EstablishmentType.TaxOffice => {
                    for (state.players) |*player, pid| {
                        if (pid == state.currentPlayerIndex) continue;
                        if (player.coins < 10) continue;
                        const halfCoins = @divTrunc(player.coins, 2);
                        player.coins -= halfCoins;
                        currentPlayer.coins += halfCoins;
                        currentPlayer.totalCoinsEarned[@enumToInt(est.type)] += halfCoins;
                    }
                },
                else => {},
            }
        }

        if (currentPlayer.coins < 0) {
            std.debug.panic("Player has negative coins!");
        } else if (currentPlayer.coins == 0) {
            currentPlayer.coins = 1; // Town Hall
        }

        const possibleCardPurchase = state.bot.getCardToPurchaseFunc(state);
        if (possibleCardPurchase) |cardToPurchase| {
            switch (cardToPurchase.type) {
                CardType.Landmark => {
                    currentPlayer.landmarks[cardToPurchase.index] = true;
                    const landmarkCost = switch (cardToPurchase.index) {
                        0 => 2,
                        1 => 4,
                        2 => 10,
                        3 => 16,
                        4 => 22,
                        5 => @intCast(i32, 30), // NOTE: Compiler bug. If everything is comptime_int it doesn't resolve to i32 and the compiler complains
                        else => std.debug.panic("Unexpected landmark {}", cardToPurchase.index),
                    };
                    currentPlayer.coins -= landmarkCost;
                    if (verboseMode) {
                        std.debug.warn("Player {} buys the {} landmark!\n", state.currentPlayerIndex, @intToEnum(Landmark, @intCast(@TagType(Landmark), cardToPurchase.index)));
                    }
                },
                CardType.Establishment => {
                    const est = &allEstablishments[cardToPurchase.index];
                    const pileCount = &state.establishmentPurchasePiles[cardToPurchase.index];
                    pileCount.* -= 1;
                    if (pileCount.* == 0) {
                        const deckToRefillFrom = switch (est.deck()) {
                            EstablishmentDeck.LowCost => &state.loEstablishmentDeck,
                            EstablishmentDeck.HighCost => &state.hiEstablishmentDeck,
                            EstablishmentDeck.Major => &state.majorEstablishmentDeck,
                        };
                        state.createEstablishmentPile(deckToRefillFrom);
                    }
                    try currentPlayer.addEstablishment(est);
                    if (verboseMode) {
                        std.debug.warn("Player {} buys a {}\n", state.currentPlayerIndex, @intToEnum(EstablishmentType, @intCast(@TagType(EstablishmentType), cardToPurchase.index)));
                    }
                },
            }
        } else {
            if (currentPlayer.landmarks[@enumToInt(Landmark.Airport)]) {
                currentPlayer.coins += 10;
            }
        }

        var currentPlayerHasWon = true;
        for (currentPlayer.landmarks) |landmarkBuilt| {
            if (!landmarkBuilt) {
                currentPlayerHasWon = false;
                break;
            }
        }
        if (currentPlayerHasWon) {
            if (verboseMode) {
                std.debug.warn("Player {} won (on turn {})!\n", state.currentPlayerIndex, state.currentTurn);
            }
            return true;
        }

        if (rolledDoubles and currentPlayer.landmarks[@enumToInt(Landmark.AmusementPark)]) {
            if (verboseMode) {
                std.debug.warn("Player {} rolled doubles and owns the amusement park. Take another turn!\n", state.currentPlayerIndex);
            }
        } else {
            state.currentPlayerIndex = (state.currentPlayerIndex + 1) % PlayerCount;
        }
        return false;
    }
};
