#include <memory>
#include <string>
#include <iostream>
#include "zmq_remote_show.hpp"
#include "opencv2/opencv.hpp"


using namespace cv;
using namespace std;

int main(int argc, char *argv[])
{
    std::cout << "Hello World!" << std::endl;
    // 10.68.4.241:1001  server   
    // client: 
    auto zmq_remote_show = create_zmq_remote_show("tcp://0.0.0.0:15556");

    Mat image = imread("workspace/3.jpg");
    while(1)
    {
        zmq_remote_show->post(image);
    }

    return 0;
}