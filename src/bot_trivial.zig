const std = @import("std");

const game = @import("game.zig");
const GameState = game.GameState;
const PurchasableCard = game.PurchasableCard;

pub fn shouldRollTwoDice(state: *GameState) bool {
    return true;
}

pub fn getCardToPurchase(state: *GameState) ?PurchasableCard {
    const player = &state.players[state.currentPlayerIndex];
    for (player.landmarks) |landmarkBuilt, landmarkIndex| {
        if (!landmarkBuilt) {
            const landmarkCost = switch (landmarkIndex) {
                0 => 2,
                1 => 4,
                2 => 10,
                3 => 16,
                4 => 22,
                5 => @intCast(i32, 30), // TODO: Compiler bug? If everything is comptime_int it doesn't resolve to i32 and the compiler complains
                else => std.debug.panic("Unexpected landmark {}", landmarkIndex),
            };
            if (landmarkCost <= player.coins) {
                return PurchasableCard{
                    .type = game.CardType.Landmark,
                    .index = landmarkIndex,
                };
            }
        }
    }

    for (game.allEstablishments) |est, i| {
        if ((state.establishmentPurchasePiles[i] > 0) and (est.cost <= player.coins)) {
            return PurchasableCard{
                .type = game.CardType.Establishment,
                .index = i,
            };
        }
    }
    return null;
}
