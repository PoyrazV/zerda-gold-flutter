const jwt = require('jsonwebtoken');

// The token from our test
const token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI5MGY3ZTIyZi03YTdmLTQ4YmEtYjU5MS04Njc3OGVjZGJmOWQiLCJlbWFpbCI6ImRlbW9AemVyZGEuY29tIiwidHlwZSI6Im1vYmlsZSIsImlhdCI6MTc1NTg2MTY5MywiZXhwIjoxNzU4NDUzNjkzfQ.UReJGPdbwVzZ1y_7VZi86VwjDtZW7Bnl20BzgxAcTOU";

// Decode without verification
const decoded = jwt.decode(token);
console.log('Decoded token:', decoded);
console.log('\nUser ID from token:', decoded.userId);
console.log('Email:', decoded.email);
console.log('Type:', decoded.type);