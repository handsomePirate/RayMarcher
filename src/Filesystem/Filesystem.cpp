#include "Filesystem.hpp"

void RMFilesystem::Init(const std::string& root)
{
	filesystem = std::make_unique<Core::Filesystem>(root);
}

const Core::Filesystem& RMFilesystem::Get() const
{
	return *filesystem.get();
}
