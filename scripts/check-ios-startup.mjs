#!/usr/bin/env node

import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

function requireContract(condition, message) {
  if (!condition) {
    throw new Error(`iOS startup contract failed: ${message}`);
  }
}

export function checkIOSStartup(projectRoot) {
  const appDelegate = readFileSync(
    resolve(projectRoot, 'ios/Runner/AppDelegate.swift'),
    'utf8',
  );
  const sceneDelegate = readFileSync(
    resolve(projectRoot, 'ios/Runner/SceneDelegate.swift'),
    'utf8',
  );
  const infoPlist = readFileSync(
    resolve(projectRoot, 'ios/Runner/Info.plist'),
    'utf8',
  );
  const xcodeProject = readFileSync(
    resolve(projectRoot, 'ios/Runner.xcodeproj/project.pbxproj'),
    'utf8',
  );

  const runnerBootstrap = `${appDelegate}\n${sceneDelegate}`;
  requireContract(
    !runnerBootstrap.includes('FlutterImplicitEngineDelegate') &&
      !runnerBootstrap.includes('didInitializeImplicitFlutterEngine'),
    'the implicit Flutter engine bootstrap returned',
  );
  requireContract(
    sceneDelegate.includes('class SceneDelegate: FlutterSceneDelegate'),
    'SceneDelegate must preserve Flutter scene lifecycle forwarding',
  );

  const engineDeclaration = sceneDelegate.match(
    /private\s+let\s+(\w+)\s*=\s*FlutterEngine\s*\(/,
  );
  requireContract(
    engineDeclaration,
    'SceneDelegate must own one explicit Flutter engine',
  );
  const engineIdentifier = engineDeclaration[1];
  const escapedEngineIdentifier = engineIdentifier.replace(
    /[.*+?^${}()|[\]\\]/g,
    '\\$&',
  );
  const orderedMarkers = [
    {
      pattern: new RegExp(`\\b${escapedEngineIdentifier}\\.run\\s*\\(`),
      label: 'the explicit engine run',
    },
    {
      pattern: new RegExp(
        `GeneratedPluginRegistrant\\.register\\s*\\(with:\\s*${escapedEngineIdentifier}\\)`,
      ),
      label: 'plugin registration',
    },
    {
      pattern: new RegExp(
        `registerSceneLifeCycle\\s*\\(with:\\s*${escapedEngineIdentifier}\\)`,
      ),
      label: 'Flutter scene lifecycle registration',
    },
    {
      pattern: /FlutterViewController\s*\(/,
      label: 'the Flutter view controller',
    },
    {
      pattern: new RegExp(`engine:\\s*${escapedEngineIdentifier}\\b`),
      label: 'the engine-backed controller argument',
    },
    {
      pattern: /\.rootViewController\s*=\s*\w+/,
      label: 'the root view controller assignment',
    },
    {
      pattern: /super\.scene\s*\(/,
      label: 'the forwarded scene connection',
    },
  ];
  let previousIndex = -1;
  for (const marker of orderedMarkers) {
    const markerIndex = sceneDelegate.search(marker.pattern);
    requireContract(
      markerIndex > previousIndex,
      `missing or misordered explicit-engine step: ${marker.label}`,
    );
    previousIndex = markerIndex;
  }

  const engineCount = sceneDelegate.match(/FlutterEngine\s*\(/g)?.length ?? 0;
  requireContract(
    engineCount === 1,
    'SceneDelegate must construct exactly one explicit Flutter engine',
  );

  const controllerCount = sceneDelegate.match(/FlutterViewController\(/g)?.length ?? 0;
  requireContract(
    controllerCount === 1,
    'SceneDelegate must construct exactly one Flutter view controller',
  );
  requireContract(
    infoPlist.includes('<string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>'),
    'Info.plist must select the app-owned SceneDelegate',
  );
  requireContract(
    !infoPlist.includes('<key>UISceneStoryboardFile</key>') &&
      !infoPlist.includes('<key>UIMainStoryboardFile</key>'),
    'an implicit Main storyboard startup key returned',
  );
  requireContract(
    /<key>CADisableMinimumFrameDurationOnPhone<\/key>\s*<true\s*\/>/.test(
      infoPlist,
    ),
    'the ProMotion frame-rate capability must remain true',
  );
  requireContract(
    xcodeProject.includes('SceneDelegate.swift in Sources'),
    'SceneDelegate.swift is not compiled into Runner',
  );
  requireContract(
    !xcodeProject.includes('Main.storyboard in Resources'),
    'the obsolete Main storyboard must not ship in Runner resources',
  );
}

const scriptPath = fileURLToPath(import.meta.url);
if (process.argv[1] && resolve(process.argv[1]) === scriptPath) {
  const projectRoot = process.argv[2]
    ? resolve(process.argv[2])
    : resolve(dirname(scriptPath), '..');
  checkIOSStartup(projectRoot);
  console.log('iOS explicit-engine startup contract passes.');
}
