const { app, BrowserWindow, Tray, Menu, nativeImage, clipboard, ipcMain } = require('electron');
const path = require('path');
const { MarkdownConverter } = require('./models/MarkdownConverter');
const { MainViewModel } = require('./viewmodels/MainViewModel');

class MarkToRTFApp {
  constructor() {
    this.mainWindow = null;
    this.tray = null;
    this.viewModel = new MainViewModel();
    this.converter = new MarkdownConverter();
    
    this.initializeApp();
  }

  initializeApp() {
    app.whenReady().then(() => {
      this.createTray();
      this.createWindow();
      this.setupIPC();
      
      app.on('activate', () => {
        if (BrowserWindow.getAllWindows().length === 0) {
          this.createWindow();
        }
      });
    });

    app.on('window-all-closed', () => {
      // Keep app running in background for menu bar access
      if (process.platform !== 'darwin') {
        app.quit();
      }
    });
  }

  createWindow() {
    this.mainWindow = new BrowserWindow({
      width: 800,
      height: 600,
      minWidth: 600,
      minHeight: 400,
      webPreferences: {
        nodeIntegration: true,
        contextIsolation: false
      },
      titleBarStyle: 'hiddenInset',
      show: false,
      skipTaskbar: true
    });

    this.mainWindow.loadFile('src/views/index.html');

    // Hide window instead of closing
    this.mainWindow.on('close', (event) => {
      event.preventDefault();
      this.mainWindow.hide();
    });

    this.mainWindow.on('ready-to-show', () => {
      this.mainWindow.show();
    });
  }

  createTray() {
    const iconPath = path.join(__dirname, '../assets/tray-icon.png');
    const trayIcon = nativeImage.createFromPath(iconPath);
    
    this.tray = new Tray(trayIcon);
    
    const contextMenu = Menu.buildFromTemplate([
      {
        label: 'Show MarkToRTF',
        click: () => {
          this.showWindow();
        }
      },
      {
        label: 'Hide MarkToRTF',
        click: () => {
          this.hideWindow();
        }
      },
      { type: 'separator' },
      {
        label: 'Quit',
        click: () => {
          app.quit();
        }
      }
    ]);

    this.tray.setToolTip('MarkToRTF - Markdown to RTF Converter');
    this.tray.setContextMenu(contextMenu);
    
    this.tray.on('click', () => {
      this.toggleWindow();
    });
  }

  showWindow() {
    if (this.mainWindow) {
      this.mainWindow.show();
      this.mainWindow.focus();
    }
  }

  hideWindow() {
    if (this.mainWindow) {
      this.mainWindow.hide();
    }
  }

  toggleWindow() {
    if (this.mainWindow) {
      if (this.mainWindow.isVisible()) {
        this.hideWindow();
      } else {
        this.showWindow();
      }
    }
  }

  setupIPC() {
    ipcMain.handle('convert-markdown-to-rtf', async (event, markdown) => {
      try {
        const rtf = await this.converter.markdownToRTF(markdown);
        clipboard.writeText(rtf);
        return { success: true, message: 'RTF copied to clipboard!' };
      } catch (error) {
        return { success: false, message: error.message };
      }
    });

    ipcMain.handle('get-clipboard-text', async () => {
      return clipboard.readText();
    });
  }
}

// Initialize the app
new MarkToRTFApp();
