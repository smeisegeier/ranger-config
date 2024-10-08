# This is a sample commands.py.  You can add your own commands here.
#
# Please refer to commands_full.py for all the default commands and a complete
# documentation.  Do NOT add them all here, or you may end up with defunct
# commands when upgrading ranger.

# A simple command for demonstration purposes follows.
# -----------------------------------------------------------------------------

from __future__ import (absolute_import, division, print_function)

# You can import any python module as needed.
import os
import subprocess
import tempfile
import time

# You always need to import ranger.api.commands here to get the Command class:
from ranger.api.commands import Command

# Any class that is a subclass of "Command" will be integrated into ranger as a
# command.  Try typing ":my_edit<ENTER>" in ranger!
class my_edit(Command):
    # The so-called doc-string of the class will be visible in the built-in
    # help that is accessible by typing "?c" inside ranger.
    """:my_edit <filename>

    A sample command for demonstration purposes that opens a file in an editor.
    """

    # The execute method is called when you run this command in ranger.
    def execute(self):
        # self.arg(1) is the first (space-separated) argument to the function.
        # This way you can write ":my_edit somefilename<ENTER>".
        if self.arg(1):
            # self.rest(1) contains self.arg(1) and everything that follows
            target_filename = self.rest(1)
        else:
            # self.fm is a ranger.core.filemanager.FileManager object and gives
            # you access to internals of ranger.
            # self.fm.thisfile is a ranger.container.file.File object and is a
            # reference to the currently selected file.
            target_filename = self.fm.thisfile.path

        # This is a generic function to print text in ranger.
        self.fm.notify("Let's edit the file " + target_filename + "!")

        # Using bad=True in fm.notify allows you to print error messages:
        if not os.path.exists(target_filename):
            self.fm.notify("The given file does not exist!", bad=True)
            return

        # This executes a function from ranger.core.acitons, a module with a
        # variety of subroutines that can help you construct commands.
        # Check out the source, or run "pydoc ranger.core.actions" for a list.
        self.fm.edit_file(target_filename)

    # The tab method is called when you press tab, and should return a list of
    # suggestions that the user will tab through.
    # tabnum is 1 for <TAB> and -1 for <S-TAB> by default
    def tab(self, tabnum):
        # This is a generic tab-completion function that iterates through the
        # content of the current directory.
        return self._tab_directory_content()

class show_files_in_finder(Command):
    """
    :show_files_in_finder

    Present selected files in finder
    """

    # def execute(self):
    #     self.fm.run('open .', flags='f')

    def execute(self):
        filepath = self.fm.thisfile.path
        os.system(f'open -R "{filepath}"')


class echo(Command):
    """:echo <text>

    Display the text in the statusbar.
    """

    def execute(self):
        self.fm.notify(self.rest(1))


class decrypt(Command):
    def execute(self):
        # * Get the current file path
        file_path = self.fm.thisfile.path
        # * Ensure the file has the .gpg extension
        if file_path.endswith('.gpg'):
            # * Remove the .gpg extension to get the output file name
            output_path = file_path[:-4]
            
            # * Create a temporary file for status information
            with tempfile.NamedTemporaryFile(delete=False) as temp_file:
                temp_file_path = temp_file.name
            
            # * Construct the gpg decryption command
            command = f"nohup gpg --batch --yes --output {output_path} --decrypt {file_path} > {temp_file_path} 2>&1 & echo $! > {temp_file_path}.pid"
            
            # * Start the decryption process
            subprocess.run(command, shell=True)
            
            # * Notify initial progress
            self.fm.notify("Decryption started...")
            
            # * Poll the process for completion
            pid_file_path = temp_file_path + '.pid'
            while os.path.exists(pid_file_path):
                with open(pid_file_path, 'r') as pid_file:
                    pid = pid_file.read().strip()
                if not pid or not os.path.exists(f"/proc/{pid}"):
                    # * Process is finished
                    os.remove(pid_file_path)
                    break
                
                # * Introduce a delay of 0.5 seconds
                time.sleep(0.5)
                
                # * Read the output and error messages
                if os.path.exists(temp_file_path):
                    with open(temp_file_path, 'r') as f:
                        output = f.read()
                    
                    if output:
                        self.fm.notify(output[:1000])  # Limit the notification to a certain length
                
                # * Refresh ranger view
                self.fm.reload_cwd()
            
            # * Notify completion
            self.fm.notify(f"Decryption of {file_path} completed.")
            
            # * Clean up temporary files
            os.remove(temp_file_path)
            if os.path.exists(pid_file_path):
                os.remove(pid_file_path)
        else:
            self.fm.notify("The selected file is not a .gpg file", bad=True)


class zip_selection(Command):
    def execute(self):
        # Get the currently selected files or directories
        selected_files = self.fm.thistab.get_selection()

        if not selected_files:
            self.fm.notify("No files selected!", bad=True)
            return

        # Determine the zip file name based on the first directory or fallback to "archive.zip"
        zip_file_name = next((file.basename for file in selected_files if file.is_directory), "archive") + ".zip"

        # Get the current directory path
        current_dir = self.fm.thisdir.path

        # Create a list of relative paths to zip, with proper quoting
        paths_to_zip = [f"'{file.relative_path}'" for file in selected_files]

        # Form the command to create the zip archive without including the root directory
        command = f"cd '{current_dir}' && zip -r '{zip_file_name}' {' '.join(paths_to_zip)} -x '*/*'"

        # Execute the command
        self.fm.run(command, shell=True)

        # Notify the user
        self.fm.notify(f"Created zip file: {zip_file_name}", bad=False)


class encrypt(Command):
    def execute(self):
        # Get the current file path
        file_path = self.fm.thisfile.path

        # Get the list of available public keys with details (key ID, user name, email, and comment)
        keys_output = subprocess.getoutput(
            "gpg --list-keys --with-colons | "
            "awk -F: '/^pub/ {key=$5} /^uid/ {print key, $10}'"
        )
        keys = keys_output.splitlines()

        if not keys:
            self.fm.notify("No GPG keys found in your keyring", bad=True)
            return

        # Use fzf to select a recipient with details
        fzf_command = "fzf --prompt='Select recipient: ' --height=10 --border --ansi"
        recipient = subprocess.getoutput(f"printf '%s\n' \"{keys_output}\" | {fzf_command}").strip()

        if not recipient:
            self.fm.notify("No recipient selected. Aborting encryption.", bad=True)
            return

        # Extract the key identifier (the first part of the selected line)
        recipient_key = recipient.split()[0]

        # Construct the gpg encryption command
        output_path = file_path + ".gpg"
        command = f"gpg --batch --yes --output {output_path} --encrypt --recipient {recipient_key} {file_path}"

        # Start the encryption process
        subprocess.run(command, shell=True)

        # Notify completion
        self.fm.notify(f"Encryption of {file_path} completed.")
        self.fm.reload_cwd()


# * alternate shell command to open in new teminal
class shell_(Command):
    def execute(self):
        if not self.arg(1):
            self.fm.notify("Usage: shell <command>", bad=True)
            return
        # Source .zshrc and run the command
        self.fm.run(f'zsh -i -c "source ~/.zshrc && {self.rest(1)} & disown"')


# bug redraw still not orking
class mount_drive(Command):
    def execute(self):
        # Step 1: Dynamically generate drive options from C-Z
        drive_options = "\n".join([chr(letter) for letter in range(ord('d'), ord('z') + 1)])

        # Use fzf to let the user select a drive letter, allowing both uppercase and lowercase input
        fzf_command = f"echo '{drive_options}' | fzf --prompt='Select drive letter: ' --height=10 --border --ansi"

        # Use os.popen to run the fzf command and capture the selected drive
        selected_drive = os.popen(fzf_command).read().strip().lower()

        if not selected_drive:
            self.fm.notify("No drive letter selected. Aborting operation.", bad=True)
            self.fm.reload_cwd()
            return

        # Step 2: Mount the selected drive
        mount_point = f"/mnt/{selected_drive}"
        mount_command = f"sudo mount -t drvfs {selected_drive.upper()}: {mount_point}"
        mount_result = os.system(mount_command)

        if mount_result != 0:
            self.fm.notify(f"Failed to mount {selected_drive.upper()}: Aborting operation.", bad=True)
            os.system('clear')  # Clear the terminal to avoid display issues
            self.fm.reload_cwd()
            self.fm.ui.redraw()  # Force a full UI redraw
            return

        # Step 3: Reload the directory view to show the mounted drive
        self.fm.notify(f"Successfully mounted {selected_drive.upper()}: to {mount_point}", bad=False)
        os.system('clear')  # Clear the terminal to avoid display issues
        self.fm.reload_cwd()
        self.fm.ui.redraw()  # Force a full UI redraw
