import { mkdirSync, renameSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'

/**
 * 把 DSH 的 Agent 运行状态写成一个小文件，供桌面桌宠轮询。
 * 状态值：type（在干活）/ idle（空闲）/ error（出错）
 */
export function apply(ctx, config) {
  const dir = config?.dir || join(process.env.LOCALAPPDATA || '', 'DshPet')
  const file = join(dir, 'state.json')
  const running = new Set()

  const write = (state) => {
    try {
      mkdirSync(dir, { recursive: true })
      const tmp = file + '.tmp'
      writeFileSync(tmp, JSON.stringify({ state, ts: Date.now() }), 'utf8')
      renameSync(tmp, file)
    } catch {
      /* 写不进去就算了，不能影响主流程 */
    }
  }

  ctx.on('agent/status', (payload) => {
    const id = String(payload?.agent?.id ?? '')
    if (payload?.status === 'running') {
      running.add(id)
      write('type')
    } else {
      running.delete(id)
      if (running.size === 0) write('idle')
    }
  })

  ctx.on('agent/error', () => {
    write('error')
  })

  write('idle')
}
