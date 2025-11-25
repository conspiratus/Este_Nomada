// Утилита для получения версии приложения
import packageJson from '../package.json';

export function getAppVersion(): string {
  return packageJson.version;
}

export function getAppName(): string {
  return packageJson.name;
}




