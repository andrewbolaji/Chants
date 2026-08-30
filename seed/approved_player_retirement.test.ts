import { strict as assert } from "assert";
import {
  APPROVED_ARSENAL_PLAYER_RETIREMENTS,
  ApprovedPlayerRetirementTransaction,
  executeApprovedArsenalPlayerRetirements,
  RetirementPlayerState,
} from "./approved_player_retirement";

function exactPlayers(): Record<string, RetirementPlayerState> {
  return Object.fromEntries(
    APPROVED_ARSENAL_PLAYER_RETIREMENTS.map((target) => [
      target.id,
      {
        exists: true,
        data: { teamId: target.teamId, name: target.name },
      },
    ])
  );
}

async function executeWithState(options?: {
  players?: Record<string, RetirementPlayerState>;
  references?: Record<string, number>;
}): Promise<{
  result: Awaited<
    ReturnType<typeof executeApprovedArsenalPlayerRetirements>
  >;
  actions: string[];
}> {
  const actions: string[] = [];
  const players = options?.players ?? exactPlayers();
  const references = options?.references ?? {};
  const result = await executeApprovedArsenalPlayerRetirements(
    async (operation) => {
      actions.push("transaction:start");
      const transaction: ApprovedPlayerRetirementTransaction = {
        readPlayer: async (id) => {
          actions.push(`read:player:${id}`);
          return players[id] ?? { exists: false };
        },
        countChantReferences: async (id) => {
          actions.push(`read:references:${id}`);
          return references[id] ?? 0;
        },
        deletePlayer: (id) => {
          actions.push(`delete:player:${id}`);
        },
      };
      return operation(transaction);
    }
  );
  return { result, actions };
}

describe("approved Arsenal player retirement", () => {
  it("pins the only three exact production deletion targets", () => {
    assert.deepEqual(APPROVED_ARSENAL_PLAYER_RETIREMENTS, [
      {
        id: "arsenal-christian-norgaard",
        teamId: "arsenal",
        name: "Christian Norgaard",
      },
      {
        id: "arsenal-leandro-trossard",
        teamId: "arsenal",
        name: "Leandro Trossard",
      },
      {
        id: "arsenal-tommy-setford",
        teamId: "arsenal",
        name: "Tommy Setford",
      },
    ]);
  });

  it("reads every identity and reference count before scheduling exact deletes", async () => {
    const { result, actions } = await executeWithState();

    assert.deepEqual(result, {
      deletedIds: APPROVED_ARSENAL_PLAYER_RETIREMENTS.map(
        (target) => target.id
      ),
      alreadyAbsentIds: [],
    });
    const firstDelete = actions.findIndex((action) =>
      action.startsWith("delete:")
    );
    assert.equal(firstDelete, 7);
    assert.deepEqual(
      actions.slice(firstDelete),
      APPROVED_ARSENAL_PLAYER_RETIREMENTS.map(
        (target) => `delete:player:${target.id}`
      )
    );
  });

  it("is idempotent when one approved target is already absent", async () => {
    const players = exactPlayers();
    players["arsenal-leandro-trossard"] = { exists: false };

    const { result, actions } = await executeWithState({ players });

    assert.deepEqual(result, {
      deletedIds: [
        "arsenal-christian-norgaard",
        "arsenal-tommy-setford",
      ],
      alreadyAbsentIds: ["arsenal-leandro-trossard"],
    });
    assert.equal(
      actions.includes("delete:player:arsenal-leandro-trossard"),
      false
    );
  });

  it("fails the whole transaction before deletion when identity changed", async () => {
    const players = exactPlayers();
    players["arsenal-leandro-trossard"] = {
      exists: true,
      data: { teamId: "another-team", name: "Leandro Trossard" },
    };
    const actions: string[] = [];

    await assert.rejects(
      executeApprovedArsenalPlayerRetirements(async (operation) =>
        operation({
          readPlayer: async (id) => {
            actions.push(`read:player:${id}`);
            return players[id];
          },
          countChantReferences: async (id) => {
            actions.push(`read:references:${id}`);
            return 0;
          },
          deletePlayer: (id) => {
            actions.push(`delete:player:${id}`);
          },
        })
      ),
      /player identity changed/
    );
    assert.equal(actions.some((action) => action.startsWith("delete:")), false);
  });

  it("fails the whole transaction before deletion when a chant references a target", async () => {
    const actions: string[] = [];

    await assert.rejects(
      executeApprovedArsenalPlayerRetirements(async (operation) =>
        operation({
          readPlayer: async (id) => {
            actions.push(`read:player:${id}`);
            return exactPlayers()[id];
          },
          countChantReferences: async (id) => {
            actions.push(`read:references:${id}`);
            return id === "arsenal-tommy-setford" ? 1 : 0;
          },
          deletePlayer: (id) => {
            actions.push(`delete:player:${id}`);
          },
        })
      ),
      /chant references exist/
    );
    assert.equal(actions.some((action) => action.startsWith("delete:")), false);
  });

  it("fails closed when a reference count is invalid", async () => {
    await assert.rejects(
      executeApprovedArsenalPlayerRetirements(async (operation) =>
        operation({
          readPlayer: async (id) => exactPlayers()[id],
          countChantReferences: async () => Number.NaN,
          deletePlayer: () => {
            throw new Error("must not delete");
          },
        })
      ),
      /could not verify chant references/
    );
  });
});
