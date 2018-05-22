for ii in node{0,1}.org0 node{0..2}.org{1,2}; do vagrant ssh $ii -c 'echo $(ip a show eth1 | grep "inet " | awk "{print \$2}" | awk -F "/" "{print \$1}" ) $(hostname) '; done 2>/dev/null
