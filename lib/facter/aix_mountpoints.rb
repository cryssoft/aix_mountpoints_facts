#
#  FACT(S):     aix_mountpoints
#
#  PURPOSE:     This custom fact returns a hash of information about the file
#		system mountpoints that are currently mounted.  [Important caveat!]
#
#  RETURNS:     (hash)
#
#  AUTHOR:      Chris Petersen, Crystallized Software
#
#  DATE:        October 22, 2021
#
#  NOTES:       Myriad names and acronyms are trademarked or copyrighted by IBM
#               including but not limited to IBM, PowerHA, AIX, RSCT (Reliable,
#               Scalable Cluster Technology), and CAA (Cluster-Aware AIX).  All
#               rights to such names and acronyms belong with their owner.
#
#		This is only necessary because Puppet doesn't collect the
#		"mountpoints" fact from AIX boxes.  Puppet sucks.
#
#-------------------------------------------------------------------------------
#
#  LAST MOD:    November 5, 2021
#
#  MODIFICATION HISTORY:
#
#  2021/10/28 - cp - Added the /ahafs test, since VIOS does things a little
#		differently from PowerHA.
#
#  2021/11/05 - cp - Added the other check for l_list[1] != '-' because there
#		some oddities in CIFS and other mounts.  Gag!
#
#  2021/11/05 - cp - Well, it takes a lot to be that stupid.  I reversed the
#		available and used calculations/columns.  Of course, AIX and
#		Linux just have to be backwards.
#
#-------------------------------------------------------------------------------
#
Facter.add(:aix_mountpoints) do
    #  This only applies to the AIX operating system
    confine :osfamily => 'AIX'

    #  
    setcode do
        #  Define the hash and array we'll need
        l_aixMpHash      = {}

        #  First, loop over 'df -k' output and build the relevant parts of the hash
        l_lines = Facter::Util::Resolution.exec("/usr/bin/df -k 2>/dev/null")
        l_lines && l_lines.split("\n").each do |l_oneLine|

            l_list = l_oneLine.split()
            if ((l_list[0] != 'Filesystem') and (l_list[0] != '/proc') and (l_list[0] != '/aha') and (l_list[0] != '/ahafs') and (l_list[1] != '-'))
                l_aixMpHash[l_list[6]] = {}
                #  Byte sizes
                l_aixMpHash[l_list[6]]['size_bytes']      = Float(l_list[1]) * 1024.0
                l_aixMpHash[l_list[6]]['available_bytes'] = Float(l_list[2]) * 1024.0
                l_aixMpHash[l_list[6]]['used_bytes']      = l_aixMpHash[l_list[6]]['size_bytes'] - l_aixMpHash[l_list[6]]['available_bytes']
                #  GiB sizes
                l_aixMpHash[l_list[6]]['size']      = sprintf("%0.2f GiB", l_aixMpHash[l_list[6]]['size_bytes'] / (1024.0*1024.0*1024.0))
                l_aixMpHash[l_list[6]]['used']      = sprintf("%0.2f GiB", l_aixMpHash[l_list[6]]['used_bytes'] / (1024.0*1024.0*1024.0))
                l_aixMpHash[l_list[6]]['available'] = sprintf("%0.2f GiB", l_aixMpHash[l_list[6]]['available_bytes'] / (1024.0*1024.0*1024.0))
                #  Capacity - Linux is a float->string, AIX will be an int->string
                l_aixMpHash[l_list[6]]['capacity']  = l_list[3]
                #  Device
                l_aixMpHash[l_list[6]]['device']    = l_list[0]
            end

        end

        #  Second, loop over 'lsfs' output and add the rest of the hash items
        l_lines = Facter::Util::Resolution.exec("/usr/sbin/lsfs 2>/dev/null")
        l_lines && l_lines.split("\n").each do |l_oneLine|

            l_list = l_oneLine.split()
            if (l_aixMpHash.has_key? (l_list[2]))
                #  File system type
                l_aixMpHash[l_list[2]]['filesystem'] = l_list[3]
                #  File system type
                l_aixMpHash[l_list[2]]['options'] = l_list[5].split(',')
            end

        end

        #  Implicitly return the contents of the hash
        l_aixMpHash
    end
end
