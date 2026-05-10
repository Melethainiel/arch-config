import { execAsync } from "ags/process"

export function run(command: string[]) {
  execAsync(command).catch((error) => console.error(error))
}
