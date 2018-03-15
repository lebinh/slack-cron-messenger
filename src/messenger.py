from __future__ import print_function
import os
import requests


SLACK_HOOK = os.environ.get('SLACK_HOOK')
MESSAGE = os.environ.get('MESSAGE')


def post_msg(hook, msg, and_print=True):
    print('Sending: "{}"'.format(msg))
    resp = requests.post(hook, json={'text': msg})
    if resp.status_code != 200:
        raise RuntimeError('Could not post message to Slack: {}'.format(resp))


def main(event, context):
    post_msg(SLACK_HOOK, MESSAGE)
