#!/usr/bin/env python3
import contextlib
import json
import os
import re
import secrets
import shlex
import shutil
import subprocess
import sys
import tempfile
import threading
import unicodedata
import urllib.request

RESET = '\033[0m'
COLORS = {'text': '#e6edf3', 'dim': '#8b949e', 'blue': '#7dd3fc',
          'purple': '#c4b5fd', 'green': '#86efac', 'red': '#fda4af', 'yellow': '#fcd34d',
          'orange': '#fb923c'}
STYLE = re.compile(r'#\[([^]]*)\]')
ANSI = re.compile(r'\033\[[0-9;]*m')
NAV_PROMPT = '󰖯  Windows › '
INFO_OPTION = '--info=hidden'
HEADER = 'j/k move · Esc close · Enter switch'
KEY_BINDINGS = 'j:down,k:up'


def color(text, shade):
    value = COLORS.get(shade, shade).lstrip('#')
    r, g, b = (int(value[i:i + 2], 16) for i in (0, 2, 4))
    return f'\033[38;2;{r};{g};{b}m{text}{RESET}'


def safe(text):
    return ''.join(c if c.isprintable() or unicodedata.category(c) == 'Co' else ' '
                   for c in text)


def icons(text):
    def replace(match):
        fg = re.search(r'fg=(#[0-9a-fA-F]{6})', match[1])
        return color('', fg[1]).removesuffix(RESET) if fg else RESET
    return STYLE.sub(replace, safe(text)) + RESET if text else color('󰆍', 'dim')


def width(text):
    return sum(0 if unicodedata.combining(c) else
               2 if unicodedata.east_asian_width(c) in ('W', 'F') else 1
               for c in ANSI.sub('', text))


def pad(text, size):
    return text + ' ' * max(0, size - width(text))


def run(args, cwd=None):
    return subprocess.run(args, cwd=cwd, capture_output=True, text=True,
                          errors='replace', timeout=2)


def git(path, *args):
    return run(['git', '--no-optional-locks', '-C', path, *args])


def numstat(text):
    added = removed = 0
    for line in text.splitlines():
        fields = line.split('\t')
        if len(fields) >= 3 and fields[0].isdigit() and fields[1].isdigit():
            added += int(fields[0])
            removed += int(fields[1])
    return added, removed


def metadata(path, cache):
    try:
        root = git(path, 'rev-parse', '--show-toplevel')
        if root.returncode:
            return '', ''
        root = root.stdout.strip()
        if root in cache:
            return cache[root]
        branch = git(root, 'symbolic-ref', '--quiet', '--short', 'HEAD').stdout.strip()
        if not branch:
            branch = '@' + git(root, 'rev-parse', '--short', 'HEAD').stdout.strip()
        options = ['--no-ext-diff', '--no-textconv', '--ignore-submodules', '--numstat']
        diff = git(root, 'diff', *options, 'HEAD', '--')
        if diff.returncode:
            staged = git(root, 'diff', '--cached', *options, '--')
            unstaged = git(root, 'diff', *options, '--')
            if staged.returncode or unstaged.returncode:
                raise ValueError('Git diff unavailable')
            diff_text = staged.stdout + unstaged.stdout
        else:
            diff_text = diff.stdout
        added, removed = numstat(diff_text)
        status = git(root, 'status', '--porcelain=v1', '-z', '--no-renames',
                     '--untracked-files=normal', '--ignore-submodules')
        if status.returncode:
            raise ValueError('Git status unavailable')
        entries = [entry for entry in status.stdout.split('\0') if entry]
        conflicts = any(entry[:2] in ('DD', 'AU', 'UD', 'UA', 'DU', 'AA', 'UU')
                        for entry in entries)
        changes = []
        if added:
            changes.append(color(f' +{added}', 'green'))
        if removed:
            changes.append(color(f' -{removed}', 'red'))
        if conflicts:
            changes.append(color(' conflict', 'red'))
        if not changes and entries:
            changes.append(color('󰏫', 'yellow'))
        cache[root] = color(' ' + safe(branch), 'purple'), '  '.join(changes)
        return cache[root]
    except (OSError, subprocess.TimeoutExpired, ValueError):
        return color(' —', 'dim'), color('󰔟 unavailable', 'dim')


def rows(paths=None):
    fields = ['session_id', 'session_name', 'window_id', 'window_index',
              'window_name', 'pane_id', 'pane_current_path',
              'pane_current_command', '@pane_agent', 'E:@pane_indicator']
    result = run(['tmux', 'list-panes', '-a', '-F',
                  '\t'.join('#{' + field + '}' for field in fields)])
    if result.returncode:
        raise RuntimeError(result.stderr.strip())
    cache = {}
    output = []
    seen_windows = set()
    for line in result.stdout.splitlines():
        (session, session_name, window, index, name, pane, path,
         command, agent, pane_indicator) = line.split('\t', 9)
        if window not in seen_windows:
            current = window == os.environ.get('PICKER_WINDOW')
            output.append((window, session, '', 'window', [
                color('', 'orange') if current else '', '',
                color(safe(f'{session_name}:{index}'), 'dim'),
                color(safe(name), 'text'), '', '',
            ]))
            seen_windows.add(window)
        directory = safe(path)
        label = agent or command
        label = 'opencode' if label == 'kitty-tmux-shim' else label
        if paths is None:
            branch, changes = metadata(directory, cache)
        else:
            paths[pane] = directory
            branch, changes = '', ''
        output.append((window, session, pane, 'pane', [
            '', icons(pane_indicator),
            color(safe(label), 'text'),
            color(' ' + directory, 'blue'), branch or color('—', 'dim'), changes,
        ]))
    return output


def render(items):
    sizes = [max((width(item[4][i]) for item in items), default=0) for i in range(6)]
    lines = []
    for window, session, pane, kind, cells in items:
        if kind == 'window':
            content = cells[3] + '  ' + cells[2]
            if cells[0]:
                content += ' ' + cells[0]
        else:
            content = '  '.join(' ' * (sizes[i] - width(cell)) + cell if i == 2 else
                                pad(cell, sizes[i]) if i < 6 else cell
                                for i, cell in enumerate(cells))
        lines.append(window + '\t' + session + '\t' + pane + '\t' + kind + '\t' + content)
    return '\n'.join(lines)


def popup_size(data, columns, lines):
    content = [row.split('\t', 4)[4] for row in data.splitlines()]
    longest = max((width(line) for line in content + HEADER.splitlines()), default=0)
    return (min(longest + 6, max(1, columns - 4)),
            min(len(content) + 6, max(1, lines - 4)))


def popup(client):
    paths = {}
    items = rows(paths)
    data = render(items)
    dimensions = run(['tmux', 'display-message', '-p', '-c', client,
                      '#{client_width} #{client_height}'])
    if dimensions.returncode:
        raise RuntimeError(dimensions.stderr.strip())
    columns, lines = map(int, dimensions.stdout.split())
    terminal_columns = columns
    columns, lines = popup_size(data, columns, lines)
    columns = min(columns + 40, max(1, terminal_columns - 4))
    with tempfile.NamedTemporaryFile(mode='w', prefix='tmux-picker-', suffix='.txt') as snapshot:
        json.dump({'items': items, 'paths': paths}, snapshot)
        snapshot.flush()
        command = ['tmux', 'display-popup', '-E', '-B', '-c', client, '-x', 'C', '-y', 'C',
                   '-w', str(columns), '-h', str(lines), '-s', 'bg=#161b22',
                   '-T', ' 󰖯 Windows ', '-e', 'PICKER_CLIENT=' + client,
                   '-e', 'PICKER_WINDOW=' + os.environ.get('PICKER_WINDOW', ''),
                   sys.executable, os.path.abspath(__file__), '--input', snapshot.name]
        return subprocess.run(command).returncode


def refresh_icons(items):
    result = run(['tmux', 'list-panes', '-a', '-F', '#{pane_id}\t#{E:@pane_indicator}'])
    if result.returncode:
        return
    indicators = dict(line.split('\t', 1) for line in result.stdout.splitlines())
    for _, _, pane, kind, cells in items:
        if kind != 'window':
            cells[1] = icons(indicators.get(pane, ''))


@contextlib.contextmanager
def animation(items, paths=None):
    with tempfile.TemporaryDirectory(prefix='tmux-picker-') as directory:
        snapshot = os.path.join(directory, 'rows')
        port_file = os.path.join(directory, 'port')
        api_key = secrets.token_hex(32)
        stopped = threading.Event()

        def load_metadata():
            cache = {}
            for _, _, pane, kind, cells in items:
                if stopped.is_set():
                    return
                if kind != 'pane':
                    continue
                branch, changes = metadata(paths[pane], cache)
                cells[4:] = [branch or color('—', 'dim'), changes]

        def update():
            previous = ''
            while not stopped.wait(.08):
                try:
                    with open(port_file) as source:
                        port = int(source.read())
                    refresh_icons(items)
                    data = render(items)
                    if data == previous:
                        continue
                    with open(snapshot + '.new', 'w') as output:
                        output.write(data)
                    os.replace(snapshot + '.new', snapshot)
                    request = urllib.request.Request(
                        f'http://127.0.0.1:{port}/', method='POST',
                        headers={'x-api-key': api_key},
                        data=f'reload-sync(cat {shlex.quote(snapshot)})'.encode())
                    with urllib.request.urlopen(request, timeout=.5):
                        pass
                    previous = data
                except (OSError, ValueError, subprocess.SubprocessError):
                    continue

        if paths:
            threading.Thread(target=load_metadata, daemon=True).start()
        worker = threading.Thread(target=update, daemon=True)
        worker.start()
        try:
            yield ['--listen=127.0.0.1:0',
                   '--bind=start:execute-silent:printf "%s" "$FZF_PORT" > ' +
                   shlex.quote(port_file)], api_key
        finally:
            stopped.set()
            worker.join()


def main():
    client = os.environ.get('PICKER_CLIENT')
    if not shutil.which('fzf') or not client:
        print('Window picker requires fzf and a tmux client.')
        return 1
    if sys.argv[1:] == ['--popup']:
        return popup(client)
    if len(sys.argv) == 3 and sys.argv[1] == '--input':
        with open(sys.argv[2]) as snapshot:
            saved = json.load(snapshot)
            items, paths = saved['items'], saved['paths']
    else:
        paths = {}
        items = rows(paths)
    data = render(items)
    with animation(items, paths) as (live_options, api_key):
        picker = subprocess.run([
            'fzf', '--ansi', '--layout=reverse', '--height=100%', '--no-multi', '--no-sort',
            '--delimiter=\t', '--with-nth=5..', '--nth=5..', INFO_OPTION,
            '--disabled', '--bind=' + KEY_BINDINGS,
            '--prompt=' + NAV_PROMPT, '--pointer=❯', '--border=sharp',
            '--border-label= 󰖯 Windows ', '--border-label-pos=0',
            '--header=' + HEADER,
            '--color=bg:#161b22,fg:#e6edf3,bg+:#1f4163,fg+:#ffffff,hl:#fcd34d,hl+:#fcd34d,pointer:#7dd3fc,prompt:#7dd3fc,header:#8b949e,info:#8b949e',
        ] + live_options, input=data, text=True, stdout=subprocess.PIPE,
           env={**os.environ, 'FZF_DEFAULT_OPTS': '', 'FZF_DEFAULT_OPTS_FILE': '',
                'FZF_API_KEY': api_key})
    if picker.returncode in (1, 130):
        return 0
    if picker.returncode:
        return picker.returncode
    window, session, pane, _, _ = picker.stdout.rstrip('\n').split('\t', 4)
    subprocess.run(['tmux', 'select-window', '-t', f'{session}:{window}'], check=True)
    if pane:
        subprocess.run(['tmux', 'select-pane', '-t', pane], check=True)
    subprocess.run(['tmux', 'switch-client', '-c', client, '-t', session], check=True)
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        print(f'Window picker: {error}', file=sys.stderr)
        sys.exit(1)
