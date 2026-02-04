#include <iostream>
#include <fstream>
#include <vector>
#include <filesystem>
#include "seal/seal.h"

using namespace std;
using namespace seal;
namespace fs = std::filesystem;

const double TEMP_THRESHOLD = 60.0;

string get_encrypted_filename(const string& result_file) {
    ifstream infile(result_file);
    string line, encrypted_file;
    while (getline(infile, line)) {
        if (line.find("ENCRYPTED_FILE=") == 0) {
            encrypted_file = line.substr(15);
        }
    }
    
    // Construiește calea completă
    fs::path result_path(result_file);
    fs::path encrypted_path = result_path.parent_path() / fs::path(encrypted_file).filename();
    return encrypted_path.string();
}

int main(int argc, char** argv) {
    if (argc < 2) {
        cerr << "Usage: " << argv[0] << " <result_file1> [result_file2] ..." << endl;
        return 1;
    }

    cout << "=== Encrypted Temperature Analysis ===" << endl;
    cout << "Threshold: " << TEMP_THRESHOLD << "°C" << endl;
    cout << "Number of clients: " << (argc - 1) << endl << endl;

    string keys_dir = fs::path(argv[1]).parent_path().string();
    if (keys_dir.empty()) keys_dir = ".";
    
    string parms_path = keys_dir + "/seal_parms.bin";
    string secret_path = keys_dir + "/secret_key.bin";

    cout << "Loading keys from: " << keys_dir << endl;

    EncryptionParameters parms;
    ifstream parms_file(parms_path, ios::binary);
    if (!parms_file) throw runtime_error("Cannot open " + parms_path);
    parms.load(parms_file);
    parms_file.close();

    SEALContext context(parms);

    SecretKey secret_key;
    ifstream sec_file(secret_path, ios::binary);
    if (!sec_file) throw runtime_error("Cannot open " + secret_path);
    secret_key.load(context, sec_file);
    sec_file.close();

    Decryptor decryptor(context, secret_key);
    CKKSEncoder encoder(context);
    Evaluator evaluator(context);

    vector<Ciphertext> encrypted_temps;

    for (int i = 1; i < argc; i++) {
        cout << "Reading " << argv[i] << "..." << endl;
        try {
            string encrypted_file = get_encrypted_filename(argv[i]);
            cout << "  Looking for: " << encrypted_file << endl;
            
            if (encrypted_file.empty()) throw runtime_error("No encrypted file found");
            
            ifstream enc_stream(encrypted_file, ios::binary);
            if (!enc_stream) throw runtime_error("Cannot open " + encrypted_file);
            
            Ciphertext temp;
            temp.load(context, enc_stream);
            enc_stream.close();
            
            encrypted_temps.push_back(temp);
            cout << "  ✓ Encrypted temperature loaded" << endl;
        } catch (exception &e) {
            cerr << "  ✗ Error: " << e.what() << endl;
        }
    }

    if (encrypted_temps.empty()) {
        cerr << "No valid encrypted temperatures!" << endl;
        return 1;
    }

    cout << "\n=== Homomorphic Computation ===" << endl;
    cout << "Computing average on encrypted data..." << endl;

    Ciphertext sum = encrypted_temps[0];
    for (size_t i = 1; i < encrypted_temps.size(); i++)
        evaluator.add_inplace(sum, encrypted_temps[i]);

    double scale = pow(2.0, 40);
    Plaintext divisor_plain;
    encoder.encode(1.0 / encrypted_temps.size(), scale, divisor_plain);

    evaluator.multiply_plain_inplace(sum, divisor_plain);
    evaluator.rescale_to_next_inplace(sum);

    Plaintext avg_plain;
    decryptor.decrypt(sum, avg_plain);
    vector<double> avg_result;
    encoder.decode(avg_plain, avg_result);

    double average_temp = avg_result[0];

    cout << "✓ Average temperature (decrypted): " << average_temp << "°C" << endl;

    cout << "\n=== Threshold Check ===" << endl;
    if (average_temp > TEMP_THRESHOLD) {
        cout << "⚠ WARNING: Average temperature EXCEEDS threshold!" << endl;
        cout << "  Average: " << average_temp << "°C" << endl;
        cout << "  Threshold: " << TEMP_THRESHOLD << "°C" << endl;
        cout << "  Difference: +" << (average_temp - TEMP_THRESHOLD) << "°C" << endl;
    } else {
        cout << "✓ OK: Average temperature within safe limits" << endl;
        cout << "  Average: " << average_temp << "°C" << endl;
        cout << "  Margin: " << (TEMP_THRESHOLD - average_temp) << "°C" << endl;
    }

    cout << "\n=== Security Benefits ===" << endl;
    cout << "✓ Individual temps remained encrypted throughout" << endl;
    cout << "✓ Server computed average without seeing individual values" << endl;
    cout << "✓ Privacy-preserving temperature monitoring" << endl;

    return 0;
}
