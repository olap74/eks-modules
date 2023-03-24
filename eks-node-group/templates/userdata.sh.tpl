#!/bin/bash -e

# Allow user supplied pre userdata code
${pre_userdata}

# Bootstrap and join the cluster: only if using custom ami
${bootstrap_userdata}
