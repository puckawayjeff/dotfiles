# Rsync Cheat Sheet

Rsync (Remote Sync) is a command-line utility for efficiently transferring and synchronizing files and directories between two locations, either on the same machine or between different machines. It is known for its delta-transfer algorithm, which minimizes data transfer by only sending the parts of files that have changed.

## Basic Syntax

The fundamental syntax for `rsync` is:

```bash
rsync [options] SOURCE DESTINATION
```

* `SOURCE`: The file or directory to be copied.
* `DESTINATION`: The location where the source will be copied.
* `[options]`: Flags that modify the command's behavior.

For remote operations, the syntax is typically `user@host:path`.

## Common Flags & Options

* `-a, --archive`: Archive mode. This is a shorthand for `-rlptgoD` and is the most common flag used. It preserves permissions, ownership, timestamps, symbolic links, and devices.
* `-v, --verbose`: Increases verbosity, showing which files are being transferred. Using `-vv` provides even more detail.
* `-h, --human-readable`: Outputs numbers in a human-readable format (e.g., K, M, G).
* `-P`: A combination of `--progress` and `--partial`. `--progress` shows a progress bar for each file transfer, and `--partial` keeps partially transferred files if the connection is interrupted, allowing the transfer to be resumed later.
* `-z, --compress`: Compresses file data during the transfer, which can speed up transfers of compressible data over slower network connections.
* `--delete`: Deletes files in the destination directory that do not exist in the source directory. This is useful for creating a true mirror of the source.
* `--exclude='PATTERN'`: Excludes files matching a specified pattern. For example, `--exclude='*.log'` would exclude all files ending in `.log`.
* `-n, --dry-run`: Performs a trial run without making any actual changes. This is highly recommended to verify that your command will do what you expect before executing it.

## Example: Push to a Remote Server

This command will copy a local directory, `/home/jeff/documents`, to the `/home/jeff/` directory on a remote server with the IP address `192.168.1.100`.

**Note the trailing slash on the source directory** `/home/jeff/documents/`. This tells `rsync` to copy the _contents_ of the directory, not the directory itself. Without the slash, a new directory named `documents` would be created inside `/home/jeff/` on the remote host.

```bash
# -a: Archive mode (preserves permissions, ownership, etc.)
# -v: Verbose output to see what's happening
# -h: Human-readable numbers
# -P: Show progress and keep partial files on interruption
# -z: Compress data during transfer
rsync -avhPz /home/jeff/documents/ jeff@192.168.1.100:/home/jeff/documents
```

## Example: Pull from a Remote Server

This command will copy the remote directory `/home/jeff/backups` from `192.168.1.100` to the local directory `/home/jeff/restored_backups`.

```bash
# This command pulls files from the remote server to the local machine.
# Note the source is the remote path and the destination is the local path.
rsync -avhPz jeff@192.168.1.100:/home/jeff/backups/ /home/jeff/restored_backups/Example: Dry Run with Deletion
```

This command shows what would happen if you ran a sync with the `--delete` flag, but it won't actually make any actual changes. This is useful for safely previewing which files would be removed from the destination.

```bash
# --dry-run: Simulate the transfer and show what would be done
# --delete:  In the simulation, show which files would be deleted from the destination
#            because they no longer exist in the source.
rsync -avhn --delete /home/jeff/documents/ jeff@192.168.1.100:/home/jeff/documents
```
