#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <fcntl.h>
#include <crypt.h>
#include <string.h>
#include <stdbool.h>
#define SIZE 512
char * invoke;
void usage()
{
	printf("syntax\n\tpw 'username:password';\n");
}
int main ( int argc, char * argv[])
{
FILE * file;
FILE * nfile;
char line[SIZE];
char newline[SIZE];
char * buffusername;
char username[SIZE];
char * password;
bool found = false;

	invoke = argv[0];
	char *buffer;
	if (argc < 2)
	{
		printf("No args\n");
		usage();
		return(1);
	}
	buffusername=strtok(argv[1], ":");
	password=strtok(NULL, "\n\0");
	if ( buffusername == NULL )
	{
		printf("Username Parse error\n");
		usage();
		return(2);
	}
	if (password == NULL)
	{
		printf("Password Parse error\n");
		usage();
		return(3);
	}
	// add : for better id matching //
	strcpy(username, buffusername);
	strcat(username, ":");
	// Open old and new files for writing //
	file = fopen("/etc/shadow", "r");
	nfile = fopen("/etc/nshadow", "w");	
	if (file == NULL){ printf("Couldn't open /etc/shadow\n"); return (5); }
	if (nfile == NULL){ printf("Couldn't open /etc/nshadow\n"); fclose(file); return (5); }
	// Read old shadow line by line //
	while (fgets(line, SIZE, file) != NULL )
	{
		// Find specified username //
		if (strncmp(username, line, strlen(username)) == 0)
		{
			// Found username //
			found = true;
			// Copy username: //
			strcpy(newline, username);
			// Copy hash //
			strcat(newline, crypt(password, "$6$Iluminati$"));
			// add : //
			strtok(line, ":");
			// discard old hash //
			strtok(NULL, ":");
			// get password age // // seperate for future manip //
			buffer=strtok(NULL, ":");
			// add : //
			strcat(newline, ":");
			// copy passowrd age //
			if (buffer == NULL ) { printf("Error Parsing Shadow File\ncheck for integrity\n"); return(6); }
			strcat(newline, buffer);
			// add : //
			strcat(newline, ":");
			// Copy rest of old shadow config //
			buffer = (strtok(NULL, "\n"));
			if (buffer == NULL ) { printf("Error Parsing Shadow File\ncheck for integrity\n"); return(6); }
			strcat(newline, buffer);
			// add EOL //
			strcat(newline, "\n");
			// Add to file //
			fputs(newline, nfile);
		}
		else
		{
			// Copy from old file to new //
			fputs(line, nfile);
		}
	}
	fclose(file);
	fclose(nfile);
	if (found == true)
	{
		rename("/etc/nshadow", "/etc/shadow");
	} else 
	{
		printf("Username Match not found\n");
		unlink("/etc/nshadow");
		return(4);
	}
	return(0);
}
