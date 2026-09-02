const { contextBridge } = require('electron');
const { execFile, execFileSync } = require('child_process');
const fs = require('fs');

const CLI = '/usr/share/welcome/welcome-cli.sh';

contextBridge.exposeInMainWorld('electronAPI', {
  // Compatível com:
  // launchCli('github')
  // launchCli('install pacote')
  // launchCli('theme dark')
  // launchCli('accent #00828c')
  // etc.
  launchCli(action) {
    if (typeof action !== 'string') {
      return false;
    }

    const args = action.trim().split(/\s+/).filter(Boolean);

    if (args.length === 0) {
      return false;
    }

    try {
      execFile(CLI, args, (error) => {
        if (error) {
          console.error('[welcome-cli]', error.message);
        }
      });

      return true;
    } catch (error) {
      console.error('[welcome-cli]', error);
      return false;
    }
  },

  // Compatível com:
  // execCli('--get-theme')
  // execCli('--get-color')
  execCli(argsString) {
    if (typeof argsString !== 'string') {
      return '';
    }

    const args = argsString.trim()
      ? argsString.trim().split(/\s+/)
      : [];

    try {
      return execFileSync(CLI, args, {
        encoding: 'utf8',
        stdio: ['ignore', 'pipe', 'pipe']
      }).trim();
    } catch (error) {
      console.error('[welcome-cli]', error.message);
      return '';
    }
  },

  // Compatível com a sua função isInstalled()
  isInstalled(pkg) {
    if (typeof pkg !== 'string') {
      return false;
    }

    // Evita caminhos arbitrários
    if (!/^[a-zA-Z0-9._-]+$/.test(pkg)) {
      return false;
    }

    try {
      return fs.existsSync(`/var/capps/${pkg}`);
    } catch (error) {
      return false;
    }
  }
});
