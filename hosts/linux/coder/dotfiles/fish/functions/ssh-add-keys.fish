function ssh-add-keys --description "Add common SSH keys to agent"
    ssh-add ~/.ssh/id_ed25519 2>/dev/null
    ssh-add ~/.ssh/id_rsa 2>/dev/null
    # Add other keys as needed
end

# NOTE: extracted from the old conf.d/ssh-agent.fish. The agent-spawning half of
# that file is not ported: Coder workspaces get SSH auth from the Coder agent
# (GIT_SSH_COMMAND / GIT_ASKPASS), and neither SSH_AUTH_SOCK nor SSH_AGENT_PID is
# set here, so the Linux branch would have started a fresh ssh-agent in every
# interactive shell.
