const std = @import("std");

const game = @import("game.zig");
const GameState = game.GameState;
const PurchasableCard = game.PurchasableCard;

const alwaysRollTwo = false; // Default: false
const alwaysActivateHarbor = false; // Default: false
const forceBuyLandmarks = false; // Default: false

pub fn shouldRollTwoDice(state: *GameState) bool {
    if (alwaysRollTwo) {
        return true;
    }

    return state.rng.random.uintAtMost(u32, 1) == 1;
}

pub fn shouldActivateHarbor(state: *GameState) bool {
    if (alwaysActivateHarbor) {
        return true;
    }

    return state.rng.random.uintAtMost(u32, 1) == 1;
}

pub fn shouldReroll(state: *GameState) bool {
    return state.rng.random.uintAtMost(u32, 1) == 1;
}

pub fn getPlayerToStealCoinsFrom(state: *GameState, coinsToSteal: u32) usize {
    while (true) {
        const victimPid = state.rng.random.uintAtMost(u32, state.players.len - 1);
        if (victimPid != state.currentPlayerIndex) return victimPid;
    }
}

pub fn getCardToPurchase(state: *GameState) ?PurchasableCard {
    var allOptions = std.ArrayList(PurchasableCard).init(state.alloc);
    allOptions.ensureCapacity(@memberCount(game.EstablishmentType) + @memberCount(game.Landmark)) catch |err| {
        std.debug.warn("Failed to allocate memory for purchasing options\n");
        return null;
    };

    var canPurchaseLandmark = false;
    const player = &state.players[state.currentPlayerIndex];
    for (player.landmarks) |landmarkBuilt, landmarkIndex| {
        if (!landmarkBuilt) {
            const landmarkCost = switch (landmarkIndex) {
                0 => 2,
                1 => 4,
                2 => 10,
                3 => 16,
                4 => 22,
                5 => @intCast(i32, 30), // TODO: Compiler bug. If everything is comptime_int it doesn't resolve to i32 and the compiler complains
                else => std.debug.panic("Unexpected landmark {}", landmarkIndex),
            };
            if (landmarkCost <= player.coins) {
                const purchase = PurchasableCard{
                    .type = game.CardType.Landmark,
                    .index = landmarkIndex,
                };
                allOptions.appendAssumeCapacity(purchase);
                canPurchaseLandmark = true;
            }
        }
    }

    if (forceBuyLandmarks and canPurchaseLandmark and (state.currentTurn > 10 * state.players.len)) {
        // Force purchase a landmark
        const resultIndex = state.rng.random.uintAtMost(usize, allOptions.count() - 1);
        return allOptions.at(resultIndex);
    }

    for (game.allEstablishments) |est, i| {
        if (state.establishmentPurchasePiles[i] <= 0) continue;
        if (est.cost > player.coins) continue;
        if (est.icon == game.CardIcon.Tower) {
            var estOwned = false;
            for (player.establishmentsYourTurn.toSliceConst()) |e| {
                if (e.type == est.type) {
                    estOwned = true;
                    break;
                }
            }
            if (estOwned) continue;
        }

        const purchase = PurchasableCard{
            .type = game.CardType.Establishment,
            .index = i,
        };
        allOptions.appendAssumeCapacity(purchase);
    }

    if (allOptions.count() == 0) return null;

    const resultIndex = state.rng.random.uintAtMost(usize, allOptions.count() - 1);
    return allOptions.at(resultIndex);
}
