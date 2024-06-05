---
- name: Secure SSH configuration
  hosts: all
  become: yes
  tasks:
    - name: Disable root SSH login
      lineinfile:
        path: /etc/ssh/sshd_config
        state: present
        regexp: '^PermitRootLogin'
        line: 'PermitRootLogin no'
      notify:
        - Restart SSH

    - name: Allow only key-based SSH authentication
      lineinfile:
        path: /etc/ssh/sshd_config
        state: present
        regexp: '^PasswordAuthentication'
        line: 'PasswordAuthentication no'
      notify:
        - Restart SSH

  handlers:
    - name: Restart SSH
      service:
        name: ssh
        state: restarted