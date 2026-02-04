#include <iostream>
#include <fstream>
#include <cstdlib>
#include <ctime>

using namespace std;

const int N = 4;

int main(int argc, char** argv) {
    if (argc < 2) {
        cerr << "Usage: " << argv[0] << " <output_file>" << endl;
        return 1;
    }
    srand(time(NULL));
    ofstream outfile(argv[1]);
    if (!outfile) {
        cerr << "Error: Cannot create file" << endl;
        return 1;
    }
    double A[N][N];
    double b[N];
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            if (i == j) {
                A[i][j] = 0.5 + (rand() % 30) / 100.0;
            } else {
                A[i][j] = (rand() % 20 - 10) / 100.0;
            }
        }
    }
    for (int i = 0; i < N; i++) {
        b[i] = (rand() % 20 + 1);
    }
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            outfile << A[i][j];
            if (j < N-1) outfile << " ";
        }
        outfile << endl;
    }
    for (int i = 0; i < N; i++) {
        outfile << b[i];
        if (i < N-1) outfile << " ";
    }
    outfile << endl;
    outfile.close();
    cout << "Input file created: " << argv[1] << endl;
    return 0;
}
