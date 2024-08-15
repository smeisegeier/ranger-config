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

        # Create a zip file name
        # If the selection includes directories, use the name of the first directory for the zip file
        include_dirs = any(file.is_directory for file in selected_files)
        if include_dirs:
            dir_name = next(file.basename for file in selected_files if file.is_directory)
            zip_file_name = f"{dir_name}.zip"
        else:
            zip_file_name = "archive.zip"

        # Get the current directory to use as the base for relative paths
        current_dir = self.fm.thisdir.path

        # Create a list of relative paths to zip
        paths_to_zip = [file.path[len(current_dir)+1:] for file in selected_files]

        # Command to create a zip file
        # Use the base directory path for the zip command
        command = f"cd '{current_dir}' && zip -r '{zip_file_name}' {' '.join(paths_to_zip)}"

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
