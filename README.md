# Task description

The program `task` accepts the pairs of words `A B` from file `input.txt`, makes a merge sort,
and then let you find by `A` (inputed from `stdin`) the `B` with the help of binary search.


## Usage

To run the task you can use the following command
```bash
$ make
```
then you'll be asked to enter the key. If the corresponding value is found it would be printed in the output, if it's not — the error message will appear, after the response you'll be able to continue making key-queries.

Here is example of work:
```bash
$ make
Enter the key: jj
val5
Enter the key: 

Enter the key: jk
Key wasn't found: jk
Enter the key: 
...

```

## Errors handling

The program reports about errors. It could be one of the following situation:

 * The file `input.txt` doesn't exist
 * The file `input.txt` is empty
 * The file parsing errors — right file format: each line should contain the key followed by one space and the value after it. Example:
      ```
       K1 V1
       
       K2 V2
       
       ```
 * The corresponding key was not found
 
 
