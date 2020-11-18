//
//  Error.h
//  audio_test
//
//  Created by Alex on 29.04.2020.
//  Copyright © 2020 Alex. All rights reserved.
//

#ifndef ERROR_HPP
#define ERROR_HPP

#include <string>


struct Error: std::exception {
    int code;
    std::string description;
    Error(int code, std::string description): code(code), description(description) {}
};


#define ThrowIfError(code, description)                                        \
do {                                                                    \
OSStatus __err = code;                                                \
if (__err) {                                                        \
throw Error(code, description);                            \
}                                                                    \
} while (0)


#endif /* Error_h */
