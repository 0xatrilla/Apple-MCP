export interface RiskyActionInput {
  confirm?: boolean;
  reason?: string;
}

export function requireConfirmation(action: string, input: RiskyActionInput): void {
  if (input.confirm !== true || !input.reason?.trim()) {
    throw new Error(`${action} requires confirm: true and a non-empty reason.`);
  }
}
