#!/usr/bin/python27

import os
import platform
from checks import AgentCheck


class PIDCheck(AgentCheck):

    @staticmethod
    def check_pid(pid):
        """ Check For the existence of a unix pid. """
        return os.path.exists("/proc/" + str(int(pid)))

    @staticmethod
    def get_file_contents(file_name):
        try:
            with open(file_name, 'r') as file_open:
                return file_open.read()
        except:
            print 'Failed to open file %s' % file_name
            return None

    def service_check_ok(self, name, tags):
        self.service_check(name, AgentCheck.OK, tags=tags)

    def service_check_warning(self, name, tags):
        self.service_check(name, AgentCheck.WARNING, tags=tags)

    def service_check_critical(self, name, tags):
        self.service_check(name, AgentCheck.CRITICAL, tags=tags)

    def event_file_read_failed(self, pid_file, instance):
        name = 'pid.%s' % instance['name']
        tags = [
            'name:%s' % instance['name'],
            'host:%s' % platform.uname()[1],
            'file:%s' % instance['pid_file'],
            'pid:failed_to_open_file',
        ]
        self.service_check_critical(name, tags)

    def event_pid_failed(self, pid, instance):
        name = 'pid.%s' % instance['name']
        tags = [
            'name:%s' % instance['name'],
            'host:%s' % platform.uname()[1],
            'file:%s' % instance['pid_file'],
            'pid:%d' % int(pid),
        ]
        self.service_check_critical(name, tags)

    def event_pid_success(self, pid, instance):
        name = 'pid.%s' % instance['name']
        tags = [
            'name:%s' % instance['name'],
            'host:%s' % platform.uname()[1],
            'file:%s' % instance['pid_file'],
            'pid:%d' % int(pid),
        ]
        self.service_check_ok(name, tags)

    def check(self, instance):
        pid_file = instance['pid_file']
        pid = PIDCheck.get_file_contents(pid_file)

        if pid is not None:
            if not PIDCheck.check_pid(pid):
                self.event_pid_failed(pid, instance)
            else:
                self.event_pid_success(pid, instance)
        else:
            self.event_file_read_failed(pid_file, instance)


def main():
    check, instances = PIDCheck.from_yaml(
        '/etc/dd-agent/conf.d/pid_check.yaml')
    for instance in instances:
        print "\nRunning the check against PID found in: %s" % (instance['pid_file'])
        check.check(instance)
        if check.has_events():
            print 'Events: %s' % (check.get_events())
        print 'Metrics: %s' % (check.get_metrics())


if __name__ == '__main__':
    main()
