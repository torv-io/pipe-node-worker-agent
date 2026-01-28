import { createRequire } from 'module';
import { readFileSync } from 'fs';
import { join } from 'path';

const require = createRequire(import.meta.url);

const workDir = process.env.WORK_DIR;
const contextJson = process.env.CONTEXT;

if (!workDir || !contextJson) {
  process.stderr.write('Error: WORK_DIR and CONTEXT environment variables must be set\n');
  process.exit(1);
}

(async () => {
  try {
    const context = JSON.parse(contextJson);
    const stageFile = join(workDir, 'stage.js');

    // Create require that resolves from workDir (finds workDir/node_modules)
    const stageRequire = createRequire(join(workDir, 'package.json'));
    
    // Load and execute stage
    const stageModule = stageRequire(stageFile);
    const stageRunner = stageModule.default;

    if (typeof stageRunner !== 'function') {
      throw new Error('Stage code must export a default function (StageRunner)');
    }

    const result = await Promise.resolve(stageRunner(context));

    if (!result || typeof result !== 'object') {
      throw new Error('Stage runner must return a StageResult object');
    }

    process.stdout.write(JSON.stringify({
      success: result.success !== false,
      outputs: result.outputs || {},
      error: result.error || null,
      metadata: result.metadata || {},
    }));

    process.exit(0);
  } catch (error) {
    process.stdout.write(JSON.stringify({
      success: false,
      outputs: {},
      error: error.message || String(error),
      metadata: {
        stack: error.stack,
      },
    }));

    process.exit(1);
  }
})();
