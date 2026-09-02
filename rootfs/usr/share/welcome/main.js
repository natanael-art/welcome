const { app, BrowserWindow } = require('electron');
const path = require('path');

// Impede múltiplas instâncias
const gotLock = app.requestSingleInstanceLock();
if (!gotLock) { app.quit(); }

function createWindow() {
  const win = new BrowserWindow({
    width:  920,
    height: 640,
    minWidth:  800,
    minHeight: 560,
    title: 'Mainuan — Bem-vindo',
    autoHideMenuBar: true,
    webPreferences: {
      preload:         path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration:  false,
    }
  });

  win.loadFile('index.html');
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => app.quit());
