const std = @import("std");
const Allocator = std.mem.Allocator;

const game = @import("game.zig");
const bot_trivial = @import("bot_trivial.zig");
const bot_rand = @import("bot_random.zig");

fn playASingleGame(turnLimit: u32, alloc: *Allocator, rng: *std.rand.Xoroshiro128) !game.GameState {
    const bot = game.BotCode{
        .shouldRollTwoDiceFunc = bot_rand.shouldRollTwoDice,
        .getCardToPurchaseFunc = bot_rand.getCardToPurchase,
        .shouldActivateHarborFunc = bot_rand.shouldActivateHarbor,
        .shouldReroll = bot_rand.shouldReroll,
        .getPlayerToStealCoinsFrom = bot_rand.getPlayerToStealCoinsFrom,
    };
    var state = try game.GameState.init(alloc, rng, bot);
    //state.print();
    //std.debug.warn("\n");
    while (state.currentTurn < turnLimit) {
        const gameover = try state.playTurn();
        if (gameover) break;
    }

    if (state.currentTurn >= turnLimit) {
        std.debug.warn("A game ran over the turn limit of {} turns!\n", turnLimit);
    }

    //state.print();
    return state;
}

pub fn main() !void {
    //const gamesToPlay = 10000000;
    const gamesToPlay = 1000000;
    //const gamesToPlay = 1000;
    const turnLimit = 300; // TODO: We don't really expect to hit this? I suppose there isn't a reason why we can't
    var totalOwnedByWinners = [_]u64{0} ** @memberCount(game.EstablishmentType);
    var totalCoinsEarnedByEstablishment = [_]i64{0} ** @memberCount(game.EstablishmentType);
    var winnerCoinsEarnedByEstablishment = [_]i64{0} ** @memberCount(game.EstablishmentType);
    std.debug.warn("Playing {} games...\n", @intCast(u32, gamesToPlay));

    var heapAlloc = std.heap.HeapAllocator.init();
    var rng = std.rand.Xoroshiro128.init(std.time.milliTimestamp());

    var t = try std.time.Timer.start();
    var currentGame: u32 = 0;
    while (currentGame < gamesToPlay) {
        var alloc = std.heap.ArenaAllocator.init(&heapAlloc.allocator);
        const endState = try playASingleGame(turnLimit, &alloc.allocator, &rng);

        var ownedByWinner = [_]u64{0} ** @memberCount(game.EstablishmentType);
        const winner = &endState.players[endState.currentPlayerIndex];
        for (winner.establishmentsAnyTurn.toSliceConst()) |est| {
            ownedByWinner[@enumToInt(est.type)] += 1;
        }
        for (winner.establishmentsYourTurn.toSliceConst()) |est| {
            ownedByWinner[@enumToInt(est.type)] += 1;
        }
        for (winner.establishmentsOtherTurns.toSliceConst()) |est| {
            ownedByWinner[@enumToInt(est.type)] += 1;
        }

        for (winner.totalCoinsEarned) |earned, estIndex| {
            winnerCoinsEarnedByEstablishment[estIndex] += earned;
        }
        for (endState.players) |*player| {
            for (player.totalCoinsEarned) |earned, estIndex| {
                totalCoinsEarnedByEstablishment[estIndex] += earned;
            }
        }
        alloc.deinit();

        for (ownedByWinner) |owned, index| {
            totalOwnedByWinners[index] += ownedByWinner[index];
        }
        currentGame += 1;
    }

    heapAlloc.deinit();

    std.debug.warn("Winner owns establishment:\n");
    for (totalOwnedByWinners) |totalOwned, estTypeIndex| {
        var est = &game.allEstablishments[estTypeIndex];
        var avgOwnedByWinners = @intToFloat(f64, totalOwned) / gamesToPlay;
        var avgEarnedByWinners = @intToFloat(f64, winnerCoinsEarnedByEstablishment[estTypeIndex]) / gamesToPlay;
        var avgEarnedByAllPlayers = @intToFloat(f64, totalCoinsEarnedByEstablishment[estTypeIndex]) / (game.PlayerCount * gamesToPlay);
        std.debug.warn("{},{d:.3},{d:.3},{d:.3}\n", @tagName(est.type), avgOwnedByWinners, avgEarnedByWinners, avgEarnedByAllPlayers);
    }

    const elapsedNs = t.read();
    const msPerNs = 1.0 / @intToFloat(f64, std.time.millisecond);
    std.debug.warn("\n\nCompleted in {}ms\n\n", @intToFloat(f64, elapsedNs) * msPerNs);
}
