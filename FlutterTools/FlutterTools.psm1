function Convert-StringCase
{
    <#
    .SYNOPSIS
    Converts a string to different casing formats (kebab, pascal, camel, snake).
    
    .DESCRIPTION
    This function takes an input string in any format and converts it to the specified case format.
    It handles inputs that are already in various formats including:
    - kebab-case
    - PascalCase
    - camelCase
    - snake_case
    - space separated
    - mixed formats
    
    .PARAMETER InputString
    The string to convert. Can be in any existing format or capitalization.
    
    .PARAMETER Format
    The target format to convert to. Valid options are:
    - kebab (kebab-case)
    - pascal (PascalCase)
    - camel (camelCase)
    - snake (snake_case)
    
    .EXAMPLE
    Convert-StringCase -InputString "hello world" -Format kebab
    Output: hello-world
    
    .EXAMPLE
    Convert-StringCase -InputString "HelloWorld" -Format snake
    Output: hello_world
    
    .EXAMPLE
    Convert-StringCase -InputString "some-kebab-case" -Format pascal
    Output: SomeKebabCase
    
    .EXAMPLE
    Convert-StringCase -InputString "mixed_Format-String example" -Format camel
    Output: mixedFormatStringExample
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$InputString,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet('kebab', 'pascal', 'camel', 'snake')]
        [string]$Format
    )
    
    process
    {
        # Handle empty or null strings
        if ([string]::IsNullOrWhiteSpace($InputString))
        {
            return $InputString
        }
        
        # Split the string into words using various delimiters and case changes
        $words = @()
        
        # First, split on common delimiters (space, dash, underscore)
        $tempWords = $InputString -split '[\s\-_]+'
        
        # Then handle camelCase and PascalCase by splitting on capital letters
        foreach ($word in $tempWords)
        {
            if ([string]::IsNullOrWhiteSpace($word))
            { continue 
            }
            
            # Split on capital letters while preserving the capital letter
            $subWords = $word -csplit '(?=[A-Z])' | Where-Object { $_ -ne '' }
            $words += $subWords
        }
        
        # Clean up words: remove empty strings and convert to lowercase
        $cleanWords = $words | Where-Object { 
            -not [string]::IsNullOrWhiteSpace($_) 
        } | ForEach-Object { 
            $_.Trim().ToLower() 
        }
        
        # Handle the case where we have no valid words
        if ($cleanWords.Count -eq 0)
        {
            return $InputString
        }
        
        # Convert to the target format
        switch ($Format)
        {
            'kebab'
            {
                return ($cleanWords -join '-')
            }
            'pascal'
            {
                return ($cleanWords | ForEach-Object { 
                        (Get-Culture).TextInfo.ToTitleCase($_) 
                    }) -join ''
            }
            'camel'
            {
                $result = $cleanWords[0].ToLower()
                if ($cleanWords.Count -gt 1)
                {
                    $result += ($cleanWords[1..($cleanWords.Count-1)] | ForEach-Object { 
                            (Get-Culture).TextInfo.ToTitleCase($_) 
                        }) -join ''
                }
                return $result
            }
            'snake'
            {
                return ($cleanWords -join '_')
            }
        }
    }
}

function Get-FlutterAppName
{
    [CmdletBinding()]
    param (
        [string]$Path = "."
    )

    $pubspecPath = Join-Path -Path $Path -ChildPath "pubspec.yaml"
    if (-not (Test-Path -Path $pubspecPath))
    {
        Write-Error "pubspec.yaml not found in the specified path: $Path"
        return
    }

    $content = Get-Content -Path $pubspecPath -Raw
    if ($content -match 'name:\s*(\S+)')
    {
        return $matches[1]
    } else
    {
        Write-Error "App name not found in pubspec.yaml"
        return 'replace-me'
    }
}

function Get-BasePackageImport
{ 
    [CmdletBinding()]
    param (
        [string]$Path = ".",
        [Parameter(Mandatory)]
        [string]$FeatureName
    )
    $appName = Get-FlutterAppName -Path $Path
    $snakeCaseFeatureName = Convert-StringCase -InputString $FeatureName -Format snake

    return "package:$appName/features/$snakeCaseFeatureName"
}


function New-ListTemplates
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FeatureName
    )
    $snakeCaseFeatureName = Convert-StringCase -InputString $FeatureName -Format snake
    $baseImport = Get-BasePackageImport -FeatureName $FeatureName
    $FeatureName = Convert-StringCase -InputString $FeatureName -Format pascal
    $UseCaseName = "Fetch${FeatureName}"
    $usecase = @"
        import '$baseImport/domain/entities/$snakeCaseFeatureName.dart';
        import '$baseImport/domain/entities/search_options.dart';
        import '$baseImport/domain/repositories/${snakeCaseFeatureName}_repository.dart';

        class $UseCaseName {
            const $UseCaseName({required ${FeatureName}Repository repository})
                : _repository = repository;

            final ${FeatureName}Repository _repository;

            Future<List<$FeatureName>> call(SearchOptions search) async {
                // Implement fetch logic here
                return [];
            }
        }
        
"@

    $entity = @"
        class $FeatureName {
            const $FeatureName({required this.id, required this.name});

            final String id;
            final String name;


            // Add other properties and methods as needed
        }
"@

    $searchOptions = @"
     class SearchOptions {
            const SearchOptions({required this.query});
            
            final String query;

            @override
            String toString() => 'SearchOptions(query: \$query)';
    }
"@

    $repository = @"
        import '$baseImport/domain/entities/$snakeCaseFeatureName.dart';
        import '$baseImport/domain/entities/search_options.dart';

        abstract class ${FeatureName}Repository {
            Future<List<$FeatureName>> fetch${FeatureName}(SearchOptions search);
        }
"@
    
    $repositoryImpl = @"
        import '$baseImport/domain/entities/$snakeCaseFeatureName.dart';
        import '$baseImport/domain/entities/search_options.dart';
        import '$baseImport/domain/repositories/${snakeCaseFeatureName}_repository.dart';

        class ${FeatureName}RepositoryImpl implements ${FeatureName}Repository {
            @override
            Future<List<$FeatureName>> fetch${FeatureName}(SearchOptions search) async {
                // Implement the actual data fetching logic here
                throw UnimplementedError('fetch${FeatureName} not implemented');
            }
        }
"@


    $dependency = @"
        import 'package:get_it/get_it.dart';
        import '$baseImport/infrastructure/${snakeCaseFeatureName}_repository_impl.dart';
        import '$baseImport/domain/repositories/${snakeCaseFeatureName}_repository.dart';
        import '$baseImport/usecase/fetch_${snakeCaseFeatureName}.dart';

        void setup${FeatureName}Dependency() {
            GetIt.instance
            ..registerLazySingleton<${FeatureName}Repository>(
                () => ${FeatureName}RepositoryImpl()
            )
            ..registerFactory<Fetch${FeatureName}>(
                () => Fetch${FeatureName}(repository: getIt<${FeatureName}Repository>())
            );
        }
"@

    $bloc = @"
        import 'package:bloc_concurrency/bloc_concurrency.dart';
        import 'package:flutter_bloc/flutter_bloc.dart';
        import 'package:freezed_annotation/freezed_annotation.dart';
        import '$baseImport/usecase/fetch_${snakeCaseFeatureName}.dart';
        import '$baseImport/domain/entities/$snakeCaseFeatureName.dart';
        import '$baseImport/domain/entities/search_options.dart';

        part '${snakeCaseFeatureName}_bloc.freezed.dart';
        part '${snakeCaseFeatureName}_events.dart';
        part '${snakeCaseFeatureName}_state.dart';

        class ${FeatureName}Bloc extends Bloc<${FeatureName}Event, ${FeatureName}State> {
            final Fetch${FeatureName} _fetch${FeatureName};

            ${FeatureName}Bloc({required Fetch${FeatureName} fetch${FeatureName}}):
                _fetch${FeatureName} = fetch${FeatureName},
            super(const ${FeatureName}Initial()) {
                on<${FeatureName}Search>(_handleSearch, transformer: sequential());
                on<${FeatureName}Refresh>(_handleRefresh, transformer: sequential());
            }

            Future<void> _handleSearch(${FeatureName}Search event, Emitter<${FeatureName}State> emit) async {
                emit(${FeatureName}Loading(searchOptions: event.searchOptions));
                try {
                    final items = await _fetch${FeatureName}(event.searchOptions);
                    emit(${FeatureName}Loaded(searchOptions: event.searchOptions, items: items));
                } on Exception catch (e) {
                    emit(${FeatureName}Error(searchOptions: event.searchOptions, message: e.toString()));
                }
            }

            Future<void> _handleRefresh(${FeatureName}Refresh event, Emitter<${FeatureName}State> emit) async {
                if (state is ${FeatureName}Loading) return; // Prevent multiple refreshes
                final currentSearchOptions = state.searchOptions;
                emit(${FeatureName}Loading(searchOptions: currentSearchOptions));
                try {
                    final items = await _fetch${FeatureName}(currentSearchOptions);
                    emit(${FeatureName}Loaded(searchOptions: currentSearchOptions, items: items));
                } on Exception catch (e) {
                    emit(${FeatureName}Error(searchOptions: currentSearchOptions, message: e.toString()));
                }
            }

        }
"@

    $state = @"
        part of '${snakeCaseFeatureName}_bloc.dart';

        @freezed
        sealed class ${FeatureName}State with _`$${FeatureName}State {
            const factory ${FeatureName}State.initial() = ${FeatureName}Initial;
            const factory ${FeatureName}State.loading({required SearchOptions searchOptions}) = ${FeatureName}Loading;
            const factory ${FeatureName}State.loaded({required SearchOptions searchOptions, required List<$FeatureName> items}) = ${FeatureName}Loaded;
            const factory ${FeatureName}State.error({required SearchOptions searchOptions, required String message}) = ${FeatureName}Error;
            const ${FeatureName}State._({required SearchOptions searchOptions});
            SearchOptions get searchOptions => throw UnimplementedError('search not implemented');
        }
"@


    $events = @"
        part of '${snakeCaseFeatureName}_bloc.dart';

        @freezed
        sealed class ${FeatureName}Event with _`$${FeatureName}Event {
            const factory ${FeatureName}Event.refresh() = ${FeatureName}Refresh;
            const factory ${FeatureName}Event.search(SearchOptions searchOptions) = ${FeatureName}Search;
        }
"@

    $view = @"
        import 'package:flutter/material.dart';
        import 'package:flutter_bloc/flutter_bloc.dart';
        import 'package:get_it/get_it.dart';

        import '$baseImport/domain/entities/search_options.dart';
        import '$baseImport/usecase/fetch_$snakeCaseFeatureName.dart';
        import '$baseImport/view/bloc/${snakeCaseFeatureName}_bloc.dart';
        import '$baseImport/view/widgets/error_view.dart';
        import '$baseImport/view/widgets/expandable_search_bar.dart';
        import '$baseImport/view/widgets/loading_view.dart';
        import '$baseImport/view/widgets/list_item_view.dart';

        class ${FeatureName}View extends StatelessWidget {
            const ${FeatureName}View({Key? key}) : super(key: key);

            @override
            Widget build(BuildContext context) {
                return BlocProvider(
                    create: (context) => ${FeatureName}Bloc(fetch${FeatureName}: GetIt.instance.get<Fetch${FeatureName}>())
                        ..add(const ${FeatureName}Event.search(SearchOptions(query: ''))),
                    child: Scaffold(
                        appBar: PreferredSize(
                            preferredSize: Size.fromHeight(kToolbarHeight),
                            child: ExpandableSearchBar(
                                title: '$FeatureName',
                                hintText: 'Search $FeatureName',
                                onSearch: (String query) {
                                    context.read<${FeatureName}Bloc>()
                                      .add(${FeatureName}Event.search(SearchOptions(query: query)));
                                },
                            ),
                        ),
                        body: BlocBuilder<${FeatureName}Bloc, ${FeatureName}State>(
                            builder: (context, state) => switch(state) {
                                ${FeatureName}Initial() => Container(),
                                ${FeatureName}Loading() => LoadingView(),
                                ${FeatureName}Loaded(:final items) => RefreshIndicator(
                                    onRefresh: () async {
                                        context.read<${FeatureName}Bloc>().add(${FeatureName}Event.refresh());
                                    },
                                    child: ListView.builder(
                                        physics: const AlwaysScrollableScrollPhysics(),
                                        itemCount: items.length,
                                        itemBuilder: (context, index) {
                                            final item = state.items[index];
                                            return ListItemView(item: item);
                                        },
                                    ),
                                ),
                                ${FeatureName}Error(:final message) => ErrorView(message: message),
                            }
                        ),
                    ),
                );
            }
        }
"@
    $errorView = @"
        import 'package:flutter/material.dart';

        class ErrorView extends StatelessWidget {
            final String message;

            const ErrorView({Key? key, required this.message}) : super(key: key);

            @override
            Widget build(BuildContext context) {
                return Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Icon(Icons.error, color: Colors.red, size: 48),
                            SizedBox(height: 16),
                            Text(message, style: TextStyle(fontSize: 18, color: Colors.red)),
                        ],
                    ),
                );
            }
        }
"@
    $loadingView = @"
        import 'package:flutter/material.dart';

        class LoadingView extends StatelessWidget {
            const LoadingView({Key? key}) : super(key: key);

            @override
            Widget build(BuildContext context) {
                return Center(
                    child: CircularProgressIndicator(),
                );
            }
        }
"@

    $listItemView = @"
        import 'package:flutter/material.dart';
        import '$baseImport/domain/entities/$snakeCaseFeatureName.dart';

        class ListItemView extends StatelessWidget {
            final $FeatureName item;

            const ListItemView({Key? key, required this.item}) : super(key: key);

            @override
            Widget build(BuildContext context) {
                return ListTile(
                    title: Text(item.name),
                    subtitle: Text('ID: ${item.id}'),
                    onTap: () {
                        // Implement item tap action
                    },
                );
            }
        }
"@

    $searchbar = @"
import 'package:flutter/material.dart';

class ExpandableSearchBar extends StatefulWidget {
   const ExpandableSearchBar({
    Key? key,
    required this.title,
    required this.onSearch,
    String? hintText,
  }) :
        hintText = hintText ?? 'Search...',
        super(key: key);

 final String title;
  final String hintText;
  final void Function(String) onSearch;


  @override
  State createState() => _ExpandableSearchBarState();
}

class _ExpandableSearchBarState extends State<ExpandableSearchBar> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: _isSearching
          ? AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 40,
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                ),
                onSubmitted: widget.onSearch,
              ),
            )
          : Text(widget.title),
      actions: [
        if (!_isSearching)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _startSearch,
          ),
      ],
      leading: _isSearching
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _stopSearch,
            )
          : null,
    );
  }
}

"@

    return @{
        "usecase" = $usecase;
        "entity" = $entity;
        "searchOptions" = $searchOptions;
        "repository" = $repository;
        "repositoryImpl" = $repositoryImpl
        "dependency" = $dependency;
        "bloc" = $bloc;
        "state" = $state;
        "events" = $events;
        "view" = $view;
        "errorView" = $errorView;
        "loadingView" = $loadingView;
        "listItemView" = $listItemView;
        "searchBar" = $searchBar;
    }

}


function New-FlutterFeatureScaffold
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FeatureName,

        [Parameter(Mandatory)]
        [hashtable]$FileContents
    )

    $featureSnake = Convert-StringCase -InputString $FeatureName -Format snake

    $basePath = "lib/features/$featureSnake"
    $folders = @(
        "$basePath/usecase",
        "$basePath/domain",
        "$basePath/domain/entities",
        "$basePath/domain/repositories",
        "$basePath/infrastructure",
        "$basePath/view",
        "$basePath/view/bloc",
        "$basePath/view/widgets"
    )

    $folders | ForEach-Object { New-Item -ItemType Directory -Force -Path $_ | Out-Null }

    foreach ($filePath in $FileContents.Keys)
    {
        $fullPath = Join-Path -Path $basePath -ChildPath $filePath
        $directory = Split-Path -Path $fullPath -Parent
        if (-not (Test-Path -Path $directory))
        {
            New-Item -ItemType Directory -Force -Path $directory | Out-Null
        }
        Set-Content -Path $fullPath -Value $FileContents[$filePath]
    }

    Write-Host "Feature '$FeatureName' scaffolded at $basePath" -ForegroundColor Green
    Write-Host "Running formatter and fixes..." -ForegroundColor Cyan
    & fvm dart fix --apply
    & fvm dart format lib
    & fvm flutter pub run build_runner build --delete-conflicting-outputs
    & fvm dart analyze
}

function New-FlutterListFeatureScaffold
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FeatureName
    )

    $snakeCaseFeatureName = Convert-StringCase -InputString $FeatureName -Format snake
    $templates = New-ListTemplates -FeatureName $FeatureName
    $fileContents = @{
        "usecase/fetch_$snakeCaseFeatureName.dart" =  $templates["usecase"];
        "domain/entities/$snakeCaseFeatureName.dart" = $templates["entity"];
        "domain/entities/search_options.dart" = $templates["searchOptions"];
        "domain/repositories/${snakeCaseFeatureName}_repository.dart" = $templates["repository"];
        "infrastructure/${snakeCaseFeatureName}_repository_impl.dart" = $templates["repositoryImpl"];
        "view/bloc/${snakeCaseFeatureName}_bloc.dart" = $templates["bloc"];
        "view/bloc/${snakeCaseFeatureName}_state.dart" = $templates["state"];
        "view/bloc/${snakeCaseFeatureName}_events.dart" = $templates["events"];
        "view/$snakeCaseFeatureName.dart" = $templates["view"];
        "view/widgets/error_view.dart" = $templates["errorView"];
        "view/widgets/loading_view.dart" = $templates["loadingView"];
        "view/widgets/list_item_view.dart" = $templates["listItemView"];
        "view/widgets/expandable_search_bar.dart" = $templates["searchBar"];
        "infrastructure/dependency.dart" = $templates["dependency"];
    }

    New-FlutterFeatureScaffold -FeatureName $FeatureName -FileContents $fileContents
}


function Set-FlutterDefaultDependencies
{
    [CmdletBinding()]
    param(
        [string]$Path = (Get-Location)
    )

    $pubspecPath = Join-Path -Path $Path -ChildPath "pubspec.yaml"
    if (-not (Test-Path -Path $pubspecPath))
    {
        Write-Error "pubspec.yaml not found in the specified path: $Path"
        return
    }

    & fvm flutter pub add freezed_annotation dev:freezed dev:build_runner bloc_concurrency flutter_bloc get_it
}

Export-ModuleMember -Function New-FlutterFeatureScaffold, New-FlutterListFeatureScaffold, Set-FlutterDefaultDependencies
