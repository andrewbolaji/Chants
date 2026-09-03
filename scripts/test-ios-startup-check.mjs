import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

import { checkIOSStartup } from './check-ios-startup.mjs';

const projectRoot = fileURLToPath(new URL('..', import.meta.url));
const baselineFiles = {
  'ios/Runner/AppDelegate.swift': readFileSync(
    join(projectRoot, 'ios/Runner/AppDelegate.swift'),
    'utf8',
  ),
  'ios/Runner/SceneDelegate.swift': readFileSync(
    join(projectRoot, 'ios/Runner/SceneDelegate.swift'),
    'utf8',
  ),
  'ios/Runner/Info.plist': readFileSync(
    join(projectRoot, 'ios/Runner/Info.plist'),
    'utf8',
  ),
  'ios/Runner.xcodeproj/project.pbxproj': readFileSync(
    join(projectRoot, 'ios/Runner.xcodeproj/project.pbxproj'),
    'utf8',
  ),
};

function withFixture(mutator) {
  const root = mkdtempSync(join(tmpdir(), 'chants-ios-startup-'));
  const files = { ...baselineFiles };
  mutator?.(files);
  for (const [path, contents] of Object.entries(files)) {
    const outputPath = join(root, path);
    mkdirSync(dirname(outputPath), { recursive: true });
    writeFileSync(outputPath, contents);
  }
  return root;
}

function expectFailure(mutator, expected) {
  const root = withFixture(mutator);
  try {
    assert.throws(() => checkIOSStartup(root), expected);
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
}

test('accepts the reviewed explicit-engine startup topology', () => {
  const root = withFixture();
  try {
    assert.doesNotThrow(() => checkIOSStartup(root));
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});

test('accepts behavior-neutral engine and variable renaming', () => {
  const root = withFixture((files) => {
    const path = 'ios/Runner/SceneDelegate.swift';
    files[path] = files[path]
      .replaceAll('flutterEngine', 'primaryEngine')
      .replace('chants-main', 'chants-primary');
  });
  try {
    assert.doesNotThrow(() => checkIOSStartup(root));
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});

test('rejects the former implicit-engine app delegate', () => {
  expectFailure(
    (files) => {
      files['ios/Runner/AppDelegate.swift'] += '\nFlutterImplicitEngineDelegate\n';
    },
    /implicit Flutter engine bootstrap returned/,
  );
});

test('rejects a view controller created before the explicit engine runs', () => {
  expectFailure(
    (files) => {
      const path = 'ios/Runner/SceneDelegate.swift';
      files[path] = files[path].replace(
        'guard flutterEngine.run() else { return }',
        'let earlyController = FlutterViewController()\n    guard flutterEngine.run() else { return }',
      );
    },
    /explicit-engine step: the Flutter view controller/,
  );
});

test('rejects a missing plugin registration', () => {
  expectFailure(
    (files) => {
      const path = 'ios/Runner/SceneDelegate.swift';
      files[path] = files[path].replace(
        'GeneratedPluginRegistrant.register(with: flutterEngine)',
        '',
      );
    },
    /explicit-engine step: plugin registration/,
  );
});

test('rejects a missing Flutter scene lifecycle registration', () => {
  expectFailure(
    (files) => {
      const path = 'ios/Runner/SceneDelegate.swift';
      files[path] = files[path].replace(
        'registerSceneLifeCycle(with: flutterEngine)',
        '',
      );
    },
    /explicit-engine step: Flutter scene lifecycle registration/,
  );
});

test('rejects forwarding scene connection before plugin registration', () => {
  expectFailure(
    (files) => {
      const path = 'ios/Runner/SceneDelegate.swift';
      const forwarding =
        '    super.scene(scene, willConnectTo: session, options: connectionOptions)';
      files[path] = files[path]
        .replace(`\n${forwarding}`, '')
        .replace(
          '    GeneratedPluginRegistrant.register(with: flutterEngine)',
          `${forwarding}\n\n    GeneratedPluginRegistrant.register(with: flutterEngine)`,
        );
    },
    /explicit-engine step: the forwarded scene connection/,
  );
});

test('rejects an implicit storyboard startup key', () => {
  expectFailure(
    (files) => {
      files['ios/Runner/Info.plist'] = files['ios/Runner/Info.plist'].replace(
        '<key>UILaunchStoryboardName</key>',
        '<key>UISceneStoryboardFile</key>\n\t\t<string>Main</string>\n\t\t<key>UILaunchStoryboardName</key>',
      );
    },
    /implicit Main storyboard startup key returned/,
  );
});

test('rejects a false ProMotion frame-rate capability value', () => {
  expectFailure(
    (files) => {
      files['ios/Runner/Info.plist'] = files['ios/Runner/Info.plist'].replace(
        '<key>CADisableMinimumFrameDurationOnPhone</key>\n\t\t<true/>',
        '<key>CADisableMinimumFrameDurationOnPhone</key>\n\t\t<false/>',
      );
    },
    /ProMotion frame-rate capability must remain true/,
  );
});

test('rejects a SceneDelegate omitted from the Runner sources', () => {
  expectFailure(
    (files) => {
      files['ios/Runner.xcodeproj/project.pbxproj'] = files[
        'ios/Runner.xcodeproj/project.pbxproj'
      ].replaceAll('SceneDelegate.swift in Sources', 'SceneDelegate.swift omitted');
    },
    /SceneDelegate.swift is not compiled into Runner/,
  );
});

test('rejects packaging the obsolete Main storyboard', () => {
  expectFailure(
    (files) => {
      files['ios/Runner.xcodeproj/project.pbxproj'] +=
        '\nMain.storyboard in Resources\n';
    },
    /obsolete Main storyboard must not ship/,
  );
});
