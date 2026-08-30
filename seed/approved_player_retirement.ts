export interface ApprovedPlayerRetirementTarget {
  id: string;
  teamId: string;
  name: string;
}

export const APPROVED_ARSENAL_PLAYER_RETIREMENTS: ReadonlyArray<ApprovedPlayerRetirementTarget> =
  [
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
  ];

export interface RetirementPlayerState {
  exists: boolean;
  data?: Record<string, unknown>;
}

export interface ApprovedPlayerRetirementTransaction {
  readPlayer(id: string): Promise<RetirementPlayerState>;
  countChantReferences(id: string): Promise<number>;
  deletePlayer(id: string): void;
}

export interface ApprovedPlayerRetirementResult {
  deletedIds: string[];
  alreadyAbsentIds: string[];
}

export function matchesApprovedPlayerRetirementIdentity(
  target: ApprovedPlayerRetirementTarget,
  data: Record<string, unknown> | undefined
): boolean {
  return data?.teamId === target.teamId && data?.name === target.name;
}

export async function executeApprovedArsenalPlayerRetirements(
  runTransaction: <T>(
    operation: (
      transaction: ApprovedPlayerRetirementTransaction
    ) => Promise<T>
  ) => Promise<T>
): Promise<ApprovedPlayerRetirementResult> {
  return runTransaction(async (transaction) => {
    const states: Array<{
      target: ApprovedPlayerRetirementTarget;
      player: RetirementPlayerState;
      chantReferenceCount: number;
    }> = [];

    for (const target of APPROVED_ARSENAL_PLAYER_RETIREMENTS) {
      const player = await transaction.readPlayer(target.id);
      const chantReferenceCount = await transaction.countChantReferences(
        target.id
      );
      states.push({ target, player, chantReferenceCount });
    }

    const deletedIds: string[] = [];
    const alreadyAbsentIds: string[] = [];
    for (const { target, player, chantReferenceCount } of states) {
      if (!Number.isInteger(chantReferenceCount) || chantReferenceCount < 0) {
        throw new Error(
          `Approved retirement could not verify chant references for "${target.id}".`
        );
      }
      if (chantReferenceCount > 0) {
        throw new Error(
          `Approved retirement blocked for "${target.id}": chant references exist.`
        );
      }
      if (!player.exists) {
        alreadyAbsentIds.push(target.id);
        continue;
      }
      if (!matchesApprovedPlayerRetirementIdentity(target, player.data)) {
        throw new Error(
          `Approved retirement blocked for "${target.id}": player identity changed.`
        );
      }
      deletedIds.push(target.id);
    }

    for (const id of deletedIds) {
      transaction.deletePlayer(id);
    }
    return { deletedIds, alreadyAbsentIds };
  });
}
