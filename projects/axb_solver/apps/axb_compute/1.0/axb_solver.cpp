#include <iostream>
#include <cstdlib>
#include <cmath>
#include <ctime>
#include <fstream>
#include <vector>
#include <unistd.h>   // for getpid()
#include <cstdlib>    // for srand()
#include <ctime>      // for time()

using namespace std;

const int N = 4;
const int NUM_WALKS = 100000;

void read_input(const char* filename, double A[N][N], double b[N]) {
    ifstream infile(filename);
    if (!infile) {
        cerr << "Error: Cannot open input file" << endl;
        exit(1);
    }
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            infile >> A[i][j];
        }
    }
    for (int i = 0; i < N; i++) {
        infile >> b[i];
    }
    infile.close();
}

double random_walk(double A[N][N], double b[N], int index) {
    const int MAX_STEPS = 100;
    double result = 0.0;
    int current_state = index;
    double weight = 1.0;
    
    for (int step = 0; step < MAX_STEPS; step++) {
        result += weight * b[current_state];
        double row_sum = 0.0;
        for (int j = 0; j < N; j++) {
            row_sum += fabs(A[current_state][j]);
        }
        if (row_sum < 1e-10) break;
        double rand_val = ((double)rand() / RAND_MAX) * row_sum;
        double cumsum = 0.0;
        int next_state = 0;
        for (int j = 0; j < N; j++) {
            cumsum += fabs(A[current_state][j]);
            if (rand_val <= cumsum) {
                next_state = j;
                break;
            }
        }
        double sign = (A[current_state][next_state] >= 0) ? 1.0 : -1.0;
        weight *= sign * row_sum;
        if (fabs(weight) < 1e-10) break;
        current_state = next_state;
    }
    return result;
}

int main(int argc, char** argv) {
    if (argc < 3) {
        cerr << "Usage: " << argv[0] << " <input_file> <output_file>" << endl;
        return 1;
    }
    srand(time(NULL) + getpid());
    double A[N][N];
    double b[N];
    double x[N] = {0.0};
    read_input(argv[1], A, b);
    cout << "Starting Ax=b solver with Ulam-von Neumann method..." << endl;
    for (int i = 0; i < N; i++) {
        double sum = 0.0;
        for (int walk = 0; walk < NUM_WALKS; walk++) {
            sum += random_walk(A, b, i);
        }
        x[i] = sum / NUM_WALKS;
        cout << "x[" << i << "] = " << x[i] << endl;
    }
    ofstream outfile(argv[2]);
    outfile << "Solution vector x:" << endl;
    for (int i = 0; i < N; i++) {
        outfile << "x[" << i << "] = " << x[i] << endl;
    }
    double residual[N];
    double norm_residual = 0.0;
    for (int i = 0; i < N; i++) {
        residual[i] = -b[i];
        for (int j = 0; j < N; j++) {
            residual[i] += A[i][j] * x[j];
        }
        norm_residual += residual[i] * residual[i];
    }
    norm_residual = sqrt(norm_residual);
    outfile << "Residual ||Ax - b|| = " << norm_residual << endl;
    cout << "Residual ||Ax - b|| = " << norm_residual << endl;
    outfile.close();
    return 0;
}
