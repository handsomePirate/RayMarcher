#include "Logger.hpp"
#include "../Filesystem/Filesystem.hpp"

#include <SoftwareCore/DefaultLogger.hpp>
#include <iostream>
#include <fstream>

void PrintConsole(const char* message, Core::LoggerSeverity severity)
{
	const char* traceSev = "[Trace] ";
	const char* debugSev = "[Debug] ";
	const char* infoSev = "[Info] ";
	const char* warnSev = "[Warn] ";
	const char* errorSev = "[Error] ";
	const char* fatalSev = "[Fatal] ";

	switch (severity)
	{
	case Core::LoggerSeverity::Trace:
		std::cout << traceSev;
		break;
	case Core::LoggerSeverity::Debug:
		std::cout << debugSev;
		break;
	case Core::LoggerSeverity::Info:
		std::cout << infoSev;
		break;
	case Core::LoggerSeverity::Warn:
		std::cout << warnSev;
		break;
	case Core::LoggerSeverity::Error:
		std::cout << errorSev;
		break;
	case Core::LoggerSeverity::Fatal:
		std::cout << fatalSev;
		break;
	}

	std::cout << message;
}

static std::ofstream output;
void PrintFile(const char* message, Core::LoggerSeverity severity)
{
	if ((int)severity < 3)
	{
		return;
	}

	const char* traceSev = "[Trace] ";
	const char* debugSev = "[Debug] ";
	const char* infoSev = "[Info] ";
	const char* warnSev = "[Warn] ";
	const char* errorSev = "[Error] ";
	const char* fatalSev = "[Fatal] ";

	switch (severity)
	{
	case Core::LoggerSeverity::Info:
		output << infoSev;
		break;
	case Core::LoggerSeverity::Warn:
		output << warnSev;
		break;
	case Core::LoggerSeverity::Error:
		output << errorSev;
		break;
	case Core::LoggerSeverity::Fatal:
		output << fatalSev;
		break;
	}

	output << message;
}

void InitLogger(const std::string& logFile)
{
	const std::string logFilePath = RMFS.GetAbsolutePath(logFile);
	output.open(logFilePath, std::ios_base::trunc);

	DefaultLogger.SetNewOutput(&PrintConsole);
	DefaultLogger.SetNewOutput(&PrintFile);
}
