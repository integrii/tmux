#!/usr/bin/env python3
"""Isolated animator regression: no real tmux server, helpers, or network."""

import math
import os
from pathlib import Path
import shlex
import shutil
import signal
import subprocess
import tempfile
import time
import unittest


ROOT = Path(__file__).resolve().parents[1]
BASH = shutil.which('bash')


class AnimatorTest(unittest.TestCase):
    def test_status_commands_are_scanned_not_redrawn(self):
        self.assertIsNotNone(BASH, 'Bash 5 or newer must be on PATH')
        version = subprocess.check_output(
            [BASH, '-c', 'echo "${BASH_VERSINFO[0]}"'], text=True)
        self.assertGreaterEqual(int(version), 5, 'Bash 5 or newer required')
        with tempfile.TemporaryDirectory(prefix='tmux-animator-test-') as directory:
            home = Path(directory)
            helpers = home / '.sh'
            helpers.mkdir()
            binary = home / 'bin'
            binary.mkdir()
            temporary = home / 'tmp'
            temporary.mkdir()
            log = home / 'tmux.log'
            mock = binary / 'tmux'
            mock.write_text(f'#!{BASH}\n' + '''
# One write per call keeps background scan and frame logs separate.
printf -v record '%s\\037' "$@"
printf '%s\\n' "$record" >> "$MOCK_LOG"
case "$1" in
  list-panes) printf '@1|%%1|12345|codex\\n' ;;
  list-clients) printf 'mock-client\\n' ;;
  show) printf 'old-format\\n' ;;
  set) ;;
  *) printf 'unexpected mock tmux command: %s\\n' "$1" >&2; exit 1 ;;
esac
''')
            mock.chmod(0o755)
            (helpers / 'tmux-agent-name.sh').write_text('''tmux_agent_name() {
  printf '%s\\n' "$EPOCHREALTIME" >> "$HOME/scans"
  printf 'codex\\n'
}
''')
            for name, label in [('tmux-weather.sh', 'weather'),
                                ('tmux-status-right.sh', 'right')]:
                script = helpers / name
                script.write_text(f'#!{BASH}\n' + f'''
printf '%s\\n' "$EPOCHREALTIME" >> "$HOME/{label}"
printf '{label}-%s\\n' "$EPOCHREALTIME"
''')
                script.chmod(0o755)
            state = temporary / f'tmux-agent-anim-{os.getuid()}' / 'state'
            state.mkdir(parents=True)
            (state / '1').write_text('working\n')
            env = {**os.environ, 'HOME': str(home), 'TMPDIR': str(temporary),
                   'PATH': str(binary) + os.pathsep + os.environ['PATH'],
                   'MOCK_LOG': str(log)}
            # Do not inherit a real tmux connection, even though tmux is mocked.
            env.pop('TMUX', None)
            started = time.monotonic()
            process = subprocess.Popen(
                [BASH, str(ROOT / 'scripts/tmux-agent-circle-animator.sh')],
                env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                text=True, start_new_session=True)
            try:
                try:
                    stdout, stderr = process.communicate(timeout=3.4)
                    self.fail(f'animator exited early: {stdout!r} {stderr!r}')
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGTERM)
                    stdout, stderr = process.communicate(timeout=5)
            finally:
                if process.poll() is None:
                    os.killpg(process.pid, signal.SIGKILL)
                    process.communicate()
            elapsed = time.monotonic() - started
            self.assertEqual(process.returncode, 0, stderr)
            self.assertEqual(stdout, '')
            self.assertFalse((state.parent / '.circle-lock').exists())

            scans = (home / 'scans').read_text().splitlines()
            weather = (home / 'weather').read_text().splitlines()
            right = (home / 'right').read_text().splitlines()
            self.assertGreaterEqual(len(scans), 2)
            self.assertLessEqual(len(scans), math.ceil(elapsed) + 1)
            self.assertEqual(len(weather), len(scans))
            self.assertEqual(len(right), len(scans))
            # After the first SECONDS boundary, rescans cannot run per frame.
            for earlier, later in zip(map(float, weather[1:]), map(float, weather[2:])):
                self.assertGreaterEqual(later - earlier, .8)

            calls = [line.split('\x1f')[:-1] for line in log.read_text().splitlines()]
            commands = []
            for args in calls:
                command = []
                for arg in args + [';']:
                    if arg == ';':
                        commands.append(command)
                        command = []
                    else:
                        command.append(arg)
            redraws = [cmd for cmd in commands if cmd[0] == 'refresh-client']
            self.assertGreaterEqual(len(redraws), 20, 'working agent must redraw rapidly')
            self.assertGreater(len(redraws), 5 * len(weather))
            for variable, prefix in [('TMUX_AGENT_STATUS_LEFT', 'weather-'),
                                     ('TMUX_AGENT_STATUS_RIGHT', 'right-')]:
                published = [cmd[3] for cmd in commands
                             if cmd[:3] == ['set-environment', '-gh', variable]]
                self.assertGreaterEqual(len(published), 2, variable)
                self.assertLessEqual(len(published), len(scans))
                self.assertTrue(all(value.startswith(prefix) for value in published))
            for option, variable in [('@pane_icons', 'TMUX_AGENT_WINDOW_1'),
                                     ('@pane_indicator', 'TMUX_AGENT_PANE_1')]:
                self.assertTrue(any(cmd[-2:] == [option, '#{' + variable + '}']
                                    for cmd in commands))

            # Execute the format installers against the mock, not a tmux server.
            log.write_text('')
            for script in ['resize-tmux-modules.sh', 'tmux-window-style.sh']:
                subprocess.run([BASH, str(ROOT / 'scripts' / script)],
                               env=env, check=True, capture_output=True, text=True)
            installed = [line.split('\x1f')[:-1] for line in log.read_text().splitlines()]
            formats = {args[2]: args[3] for args in installed if args[:2] == ['set', '-g']}
            self.assertIn('#{TMUX_AGENT_STATUS_LEFT}', formats['status-left'])
            self.assertEqual(formats['status-right'], '#{TMUX_AGENT_STATUS_RIGHT}')
            self.assertTrue(all('#(' not in value for value in formats.values()))
            for option in ['window-status-format', 'window-status-current-format']:
                self.assertIn('#{E:@pane_icons}', formats[option])
            modules = (ROOT / 'config/theme/modules.conf').read_text()
            initial_right = [shlex.split(line)[-1] for line in modules.splitlines()
                             if line.startswith('set -g status-right ')]
            self.assertEqual(initial_right, ['#{TMUX_AGENT_STATUS_RIGHT}'])
            self.assertIn('run-shell -b "~/.sh/tmux-agent-circle-animator.sh"', modules)
            print(f'{len(redraws)} redraws; {len(scans)} scans; '
                  f'{len(weather)} weather / {len(right)} right calls')


if __name__ == '__main__':
    unittest.main()
