# NIT Silchar Auto-Login Network Tool

A lightweight, fully automated tool designed for NIT Silchar students to bypass captive portal login screens and resolve recurring "Unidentified Network" or duplicate network profile bugs on Windows.

Once installed, this tool runs silently in the background. Whenever you connect an Ethernet cable or connect to the campus network, it automatically secures your connection and passes your credentials through the NITS captive portal—without you ever needing to open a browser.

> ⚠️ **IMPORTANT DISCLAIMER:** This tool automates the login process and fixes local Windows IP bugs. **It cannot magically create an internet connection if the campus network or main server is actually down.** If the college internet is offline for everyone, this tool will simply wait until the connection is restored by the admins.

---

## 🛡️ 100% Safe and Open Source
Understandably, downloading an `.exe` file off the internet can feel a bit sketchy. **Rest assured, this tool is completely safe, private, and free of malware.** 

The entire source code (`Install_NITS_Network.bat`) is uploaded right here in the repository for full transparency. You can open it, read the code, and see exactly what it does behind the scenes (it strictly uses standard Windows network commands and a standard Python Selenium script). Your password never leaves your own computer.

*Note: Because this is a custom tool built by a student and not a massive software corporation, your browser or Windows Defender might show a "Windows protected your PC" or "Unrecognized app" warning. This is a normal false positive. Just click **More info** -> **Run anyway**!*

---

## 🚀 How to Install and Use

1. Download the latest `NITS_AutoLogin_Installer.exe` from the **Releases** section.
2. Double-click the `.exe` file to run it.
3. The setup will automatically request Administrator permissions (required to configure background network tasks).
4. Follow the on-screen prompts to enter your **NITS Username**, **Password**, and your correct **Ethernet Name**.
5. You are done! The script will automatically install the necessary Python libraries (Selenium), configure Windows Task Scheduler, and run silently on every future connection.

---

## 🔧 Troubleshooting: "Network Reset" Bug
If you ever use the Windows "Network Reset" feature in your PC Settings, Windows will wipe its cache and change your Ethernet name (e.g., from `Network` to `Network 10`). 

If the auto-login stops working after a reset, **simply run the `.exe` installer again!** It will remember your saved username and password, and just ask you to type in your new Ethernet name to instantly fix the automation.

---

## 📢 Spread the Word!
If this tool saved you from the daily headache of manual logins and bugged networks, **share this GitHub link with your friends and batchmates!** Let's get the entire NITS campus connected seamlessly so we can spend less time fighting the captive portal and more time actually getting things done.

---

## 🛠️ Developer Guide: Future-Proofing the Script

In the future, the college administration may update the IT infrastructure, change the captive portal URL, or redesign the login page. If the tool stops working for everyone, it is up to the community to update it! 

Here is exactly how to update the source code, fix the automation, and compile a new `.exe` for your peers.

### Step 1: Update the Portal URL
If the URL changes from the current `http://10.10.10.1:8090/httpclient.html`:
1. Open the source `Install_NITS_Network.bat` file in a text editor (like VS Code or Notepad).
2. Scroll down to the Python script section.
3. Locate this exact line:
   ```python
   PORTAL_URL = "[http://10.10.10.1:8090/httpclient.html](http://10.10.10.1:8090/httpclient.html)"
4. Replace the URL with the new address the college is using.

### Step 2: Fix the Login Selectors using AI
If the visual layout of the new portal changes, the Python script won't know where to type the username and password. You can easily fix this using AI (like Gemini or ChatGPT).

1. Open the new captive portal in your browser.
2. Take a clear screenshot of the entire login box.
3. Provide the AI with your `Install_NITS_Network.bat` source code and the screenshot of the new portal.
4. Use this prompt:
   > *"Here is a Python Selenium script used for a captive portal, and a screenshot of the newly updated portal page. Please update the XPath selectors in the auto_login() function to correctly target the new Username field, Password field, and Sign In button based on this image."*
5. Copy the updated Python code provided by the AI and replace the old Python block inside your `.bat` file.

### Step 3: Rebuild the `.exe` Installer
Because the `.bat` file has been modified, the old `.exe` will no longer work. You must compile a new one using **WinRAR** (you will need to have WinRAR installed on your PC to do this step):

1. Right-click your updated `Install_NITS_Network.bat` file and select **Add to archive...**
2. **General Tab:** Check **Create SFX archive** (the file extension will change to `.exe`).
3. **Advanced Tab:** Click **SFX options...**
4. **Setup Tab:** Under "Run after extraction", type exactly: `Install_NITS_Network.bat`
5. **Modes Tab:** Check **Unpack to temporary folder** and select **Hide all**.
6. **Advanced Tab (Inside SFX Options):** Check **Request administrative access**.
7. Click **OK** twice to compile your new executable.

### Step 4: Share Your Fix!
Open Source relies on collaboration. Once you have tested your new `.exe` and confirmed it logs you into the new campus network:

1. Fork this repository.
2. Upload the updated `Install_NITS_Network.bat` source code.
3. Upload your newly compiled `.exe` to the Releases page.
4. Share the link with your classmates so everyone's internet starts working automatically again!

---

## 🌟 Passing the Torch: A Legacy for NITS
Code is only as good as the community that maintains it. As network infrastructures evolve, portal layouts change, and new Windows updates roll out, this script will eventually need a tune-up. 

I built this tool to solve a daily frustration for us, but I won't be here forever. I am leaving this repository open and fully documented so that the next generation of students—especially those coming up through the Department of Computer Science and Engineering—can take ownership of it. 

If you find a way to make the script faster, adapt it for a new captive portal, or add new features, **fork this repository**, push your changes, and share the updated tool with the campus. 

Keep the automation alive, save your peers countless hours of frustration, and continue the legacy of building tools that make life at NIT Silchar just a little bit easier for everyone. 

Happy coding!
