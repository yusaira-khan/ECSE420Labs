import os

test_picture="pics/S4_E23_Lightning_shows_Prince_Huge.png"

def run_test(file, prog,  num_threads):

    cmd = "time ./%s %s  %s %s" % (prog, file, file+prog+num_threads, num_threads)
    print "Running command: " + cmd
    # print "> %s : " % file
    os.system(cmd)
    print ""




for prog in ["rectify","pool","convolve"]:
    for num in ["1","2","4","8","16","32"]:
        run_test(test_picture,prog,num)
        print ""
