#pragma once
#include <SoftwareCore/Filesystem.hpp>
#include <SoftwareCore/Singleton.hpp>
#include <memory>
#include <string>

class RMFilesystem
{
public:
	void Init(const std::string& root);
	const Core::Filesystem& Get() const;
private:
	std::unique_ptr<Core::Filesystem> filesystem;
};

#define RMFS (::Core::Singleton<::RMFilesystem>::GetInstance().Get())
