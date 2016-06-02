#!/usr/bin/python27

import platform
import os

try:
    from datadog import initilialize
except ImportError:
    print 'DEBUG: Failed to find datadog.initialize, try installing datadog '\
        'using `pip install datadog`'

try:
    from datadog import api
except ImportError:
    print 'DEBUG: Failed to find datadog.api, try installing datadog using '\
        '`pip install datdog`'


options = {
    'api_key': 'api_key',
    'app_key': 'app_key'
}

initialize(**options)


def check_pid(pid):
    """ Check For the existence of a unix pid. """
    try:
        os.kill(pid, 0)
    except OSError:
        return False
    else:
        return True


def get_file_contents(file_name):
    with open(file_name, 'r') as file_open:
        return file_open.read()


def create_event(title, description):
    tags = [
        'version:1',
        'application:jetty'
    ]

    api.Event.create(
        title=title,
        text=description,
        tags=tags,
        host=platform.uname()[1]
    )


def event_jetty_failed(pid):
    title = 'Jetty process stopped'
    description = 'When checking &d to confirm jetty was running we could not '\
        'find the process' % pid
    create_event(
        title=title,
        description=description
    )


def main():
    pid_file = '/var/run/jetty.pid'
    pid = get_file_contents(pid_file)

    if not check_pid(pid):
        event_jetty_failed(pid)

if __name__ == '__main__':
    main()
